//
//  EntityScaffold.h
//  SjekkUt
//
//  Created by Henrik Hartz on 30/03/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@interface EntityScaffold : NSManagedObject

+ (NSEntityDescription *)entity;
+ (NSFetchRequest *)fetch;

+ (id)insert;
+ (id)insertTemporary;

+ (NSArray *)allEntities;
+ (NSArray *)entitiesWithPredicate:(NSPredicate *)predicate;
+ (void)deleteAll;

@end
