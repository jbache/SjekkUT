//
//  Place+CoreDataProperties.h
//  SjekkUt
//
//  Created by Henrik Hartz on 03/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Checkin.h"
#import "Place.h"

NS_ASSUME_NONNULL_BEGIN

@interface Place (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *distance;
@property (nullable, nonatomic, retain) NSNumber *elevation;
@property (nullable, nonatomic, retain) NSString *identifier;
@property (nullable, nonatomic, retain) NSNumber *latitude;
@property (nullable, nonatomic, retain) NSNumber *longitude;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSSet<Checkin *> *checkins;
@property (nullable, nonatomic, retain) NSSet<Project *> *projects;

@end

@interface Place (CoreDataGeneratedAccessors)

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
