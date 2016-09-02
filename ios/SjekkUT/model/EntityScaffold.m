//
//  EntityScaffold.m
//  SjekkUt
//
//  Created by Henrik Hartz on 30/03/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "EntityScaffold.h"
#import "ModelController.h"

@implementation EntityScaffold

+ (NSString *)entityName
{
    return NSStringFromClass([self class]);
}

+ (NSEntityDescription *)entity
{
    return [NSEntityDescription entityForName:self.entityName
                       inManagedObjectContext:model.managedObjectContext];
}

+ (NSFetchRequest *)fetch
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    fetchRequest.entity = [self entity];
    fetchRequest.includesPendingChanges = YES;

    return fetchRequest;
}

+ (id)insert
{
    return [[[self class] alloc] initWithEntity:self.entity
                 insertIntoManagedObjectContext:model.managedObjectContext];
}

+ (id)insertTemporary
{
    return [[[self class] alloc] initWithEntity:self.entity
                 insertIntoManagedObjectContext:model.managedObjectContext];
}

+ (NSArray *)allEntities
{
    NSFetchRequest *fr = [self fetch];
    NSError *err;
    NSArray *allEntities = [[model managedObjectContext] executeFetchRequest:fr error:&err];
    if (err)
    {
        NSLog(@"[%@ allEntities] failed: %@", NSStringFromClass([self class]), err);
        return @[];
    }
    return allEntities;
}

+ (NSArray *)entitiesWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *fr = [self fetch];
    fr.predicate = predicate;
    NSError *err;
    NSArray *entitiesWithPredicate = [[model managedObjectContext] executeFetchRequest:fr error:&err];
    if (err)
    {
        NSLog(@"[%@ allEntities] failed: %@", NSStringFromClass([self class]), err);
        return @[];
    }
    return entitiesWithPredicate;
}

+ (void)deleteAll
{
    if (model.managedObjectContext == nil)
    {
        return;
    }
    NSFetchRequest *allEntities = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:self.entityName
                                                         inManagedObjectContext:model.managedObjectContext];
    [allEntities setEntity:entityDescription];
    [allEntities setIncludesPropertyValues:NO];

    NSError *error = nil;
    NSArray *allObjects = [model.managedObjectContext executeFetchRequest:allEntities
                                                                    error:&error];
    //error handling goes here
    for (NSManagedObject *anObject in allObjects)
    {
        [model.managedObjectContext deleteObject:anObject];
    }
    [model save];
}

- (void) delete
{
    if (model.managedObjectContext == nil)
    {
        return;
    }
    [model.managedObjectContext deleteObject:self];
}

@end
