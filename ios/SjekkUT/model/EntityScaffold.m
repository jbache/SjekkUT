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

+ (NSEntityDescription *)entity
{
    return [NSEntityDescription entityForName:NSStringFromClass([self class])
                       inManagedObjectContext:model.managedObjectContext];
}

+ (NSFetchRequest *)fetch
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    fetchRequest.entity = [self entity];

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

@end
