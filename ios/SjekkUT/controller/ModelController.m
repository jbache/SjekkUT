
//
//  ModelController.m
//  SjekkUt
//
//  Created by Henrik Hartz on 04/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "Defines.h"
#import "ModelController.h"

@implementation NSError (fail)

- (void)fail
{
    if (self)
    {
        NSLog(@"Unresolved error %@, %@", self, [self userInfo]);
        abort();
    }
}

- (void)warn:(NSString *)message
{
    if (self)
    {
        NSLog(@"%@: %@, %@", message, self, [self userInfo]);
    }
}

@end

@implementation NSString (URL)
- (NSURL *)URL
{
    return [NSURL URLWithString:self];
}
@end

@interface ModelController ()

@property (strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (strong) NSManagedObjectContext *privateContext;
@property (strong, nonatomic) NSMutableArray *delayUntilReady;

@property (copy) InitCallbackBlock initCallback;

- (void)initializeCoreData;

@end

@implementation ModelController

#pragma mark - Core Data stack

- (id)initWithCallback:(InitCallbackBlock)callback;
{
    if (!(self = [super init]))
        return nil;

    self.delayUntilReady = [@[] mutableCopy];

    [self setInitCallback:callback];
    [self initializeCoreData];

    return self;
}

- (void)delayUntilReady:(void (^)(void))aCallback
{
    if (self.managedObjectContext == nil)
    {
        [self.delayUntilReady addObject:[aCallback copy]];
    }
    else
    {
        aCallback();
    }
}

- (void)initializeCoreData
{
    if (self.managedObjectContext)
        return;

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"SjekkUt" withExtension:@"momd"];
    NSManagedObjectModel *moModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSAssert(moModel, @"%@:%@; no model", [self class], NSStringFromSelector(_cmd));

    NSPersistentStoreCoordinator *psCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:moModel];
    NSAssert(psCoordinator, @"%@:%@; no coordinator", [self class], NSStringFromSelector(_cmd));

    NSManagedObjectContext *mObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    NSAssert(mObjectContext, @"%@:%@; no main object context", [self class], NSStringFromSelector(_cmd));
    //[self setManagedObjectContext:mObjectContext];

    NSManagedObjectContext *pObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    //[self setPrivateContext:pObjectContext];
    NSAssert(pObjectContext, @"%@:%@; no private object context", [self class], NSStringFromSelector(_cmd));

    [pObjectContext setPersistentStoreCoordinator:psCoordinator];
    [mObjectContext setParentContext:pObjectContext];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSPersistentStoreCoordinator *psc = [pObjectContext persistentStoreCoordinator];
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        options[NSMigratePersistentStoresAutomaticallyOption] = @YES;
        options[NSInferMappingModelAutomaticallyOption] = @YES;
        //options[NSSQLitePragmasOption] = @{ @"journal_mode":@"WAL" };

        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *documentsURL = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *storeURL = [documentsURL URLByAppendingPathComponent:@"SjekkUt.sqlite"];
        NSError *error = nil;

        //NSLog(@"storeURL: %@", storeURL);

        // Check if we need a migration
        NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:storeURL error:&error];
        [error warn:@"Unable to find existing model"];

        NSManagedObjectModel *destinationModel = [psc managedObjectModel];
        BOOL isModelCompatible = (sourceMetadata == nil) || [destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
        if (!isModelCompatible)
        {
            NSLog(@"We need a migration, so we set the journal_mode to DELETE");
            options[NSSQLitePragmasOption] = @{ @"journal_mode" : @"DELETE" };
        }

        error = nil;
        NSPersistentStore *persistentStore = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
        if (error != nil)
        {
            [error warn:@"flushing database"];
            [self.managedObjectContext lock];
            NSArray *stores = [psc persistentStores];
            for (NSPersistentStore *store in stores)
            {
                [psc removePersistentStore:store error:nil];
                [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
            }
            [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:nil];

            [self.managedObjectContext unlock];
            [self setPrivateContext:nil];
            [self setManagedObjectContext:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self initializeCoreData];
            });
            return;
        }

        // Reinstate the WAL journal_mode
        if (!isModelCompatible)
        {
            NSLog(@"model was migrated, reinstate journal_mode WAL");
            error = nil;
            [psc removePersistentStore:persistentStore error:&error];
            [error fail];
            options[NSSQLitePragmasOption] = @{ @"journal_mode" : @"WAL" };
            error = nil;
            persistentStore = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
            [error fail];
        }

        //NSLog(@"set up core data successfully: %@", persistentStore);

        // only set external API once we're at this point
        [self setPrivateContext:pObjectContext];
        [self setManagedObjectContext:mObjectContext];

        if (![self initCallback])
            return;

        dispatch_sync(dispatch_get_main_queue(), ^{
            [self initCallback]();
        });
    });
}

+ (ModelController *)instance
{
    static ModelController *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[ModelController alloc] initWithCallback:^{
            //NSLog(@"posting %@", SjekkUtDatabaseModelReadyNotification);
            [defaultNotifyer postNotificationName:SjekkUtDatabaseModelReadyNotification object:model];
            typedef void (^DelayedCallback)();
            for (DelayedCallback aCallback in _instance.delayUntilReady)
            {
                aCallback();
            }
            [_instance.delayUntilReady removeAllObjects];
        }];
    });

    return _instance;
}

#pragma mark - Core Data Saving support

- (void)save;
{
    if (![[self privateContext] hasChanges] && ![[self managedObjectContext] hasChanges])
        return;

    /*    if ([[self privateContext] hasChanges])
        NSLog(@"saving private data, %@ inserted, %@ update, %@ deleted",
              @([[self privateContext] insertedObjects].count),
              @([[self privateContext] updatedObjects].count),
              @([[self privateContext] deletedObjects].count));

    if ([[self managedObjectContext] hasChanges])
        NSLog(@"saving public data, %@ inserted, %@ update, %@ deleted",
              @([[self managedObjectContext] insertedObjects].count),
              @([[self managedObjectContext] updatedObjects].count),
              @([[self managedObjectContext] deletedObjects].count));
*/
    [[self managedObjectContext] performBlockAndWait:^{
        NSError *error = nil;

        if (![[self managedObjectContext] save:&error])
        {
            NSLog(@"Failed to save main context: %@\n%@", [error localizedDescription], [error userInfo]);
        }
        else
        {
            //            NSLog(@"saved main context");
        }

        [[self privateContext] performBlock:^{
            NSError *privateError = nil;
            if (![[self privateContext] save:&privateError])
            {
                NSLog(@"Error saving private context: %@\n%@", [privateError localizedDescription], [privateError userInfo]);
            }
            else
            {
                //                NSLog(@"saved private context");
            }
        }];
    }];
}

@end
