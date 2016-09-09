//
//  EntityScaffold.h
//  SjekkUt
//
//  Created by Henrik Hartz on 30/03/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

// only assing the value if it's not equal, to prevent unneccesary Core Data changes
#define setIfNotEqual(toSet, value) \
    if (![toSet isEqual:value])     \
    {                               \
        toSet = value;              \
    }

@interface EntityScaffold : NSManagedObject

+ (NSEntityDescription *)entity;
+ (NSFetchRequest *)fetch;

+ (id)insert;
+ (id)insertTemporary;

+ (NSArray *)allEntities;
+ (NSArray *)entitiesWithPredicate:(NSPredicate *)predicate;
+ (void)deleteAll;
- (void) delete;

@end
