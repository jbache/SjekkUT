//
//  DntGroup+CoreDataProperties.h
//  SjekkUt
//
//  Created by Henrik Hartz on 16/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "DntGroup.h"

NS_ASSUME_NONNULL_BEGIN

@interface DntGroup (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *identifier;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *naming;
@property (nullable, nonatomic, retain) NSSet<Project *> *projects;

@end

@interface DntGroup (CoreDataGeneratedAccessors)

- (void)addProjectsObject:(Project *)value;
- (void)removeProjectsObject:(Project *)value;
- (void)addProjects:(NSSet<Project *> *)values;
- (void)removeProjects:(NSSet<Project *> *)values;

@end

NS_ASSUME_NONNULL_END
