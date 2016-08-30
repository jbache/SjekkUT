//
//  DntUser+CoreDataProperties.h
//  SjekkUt
//
//  Created by Henrik Hartz on 30/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "DntUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface DntUser (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *firstName;
@property (nullable, nonatomic, retain) NSString *identifier;
@property (nullable, nonatomic, retain) NSString *lastName;
@property (nullable, nonatomic, retain) NSNumber *publicCheckins;
@property (nullable, nonatomic, retain) NSSet<Checkin *> *checkins;
@property (nullable, nonatomic, retain) NSSet<Project *> *projects;

@end

@interface DntUser (CoreDataGeneratedAccessors)

- (void)addCheckinsObject:(Checkin *)value;
- (void)removeCheckinsObject:(Checkin *)value;
- (void)addCheckins:(NSSet<Checkin *> *)values;
- (void)removeCheckins:(NSSet<Checkin *> *)values;

- (void)addProjectsObject:(Project *)value;
- (void)removeProjectsObject:(Project *)value;
- (void)addProjects:(NSSet<Project *> *)values;
- (void)removeProjects:(NSSet<Project *> *)values;

@end

NS_ASSUME_NONNULL_END
