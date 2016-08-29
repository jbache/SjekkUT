//
//  Place+CoreDataProperties.h
//  SjekkUt
//
//  Created by Henrik Hartz on 29/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Place.h"

NS_ASSUME_NONNULL_BEGIN

@interface Place (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *county;
@property (nullable, nonatomic, retain) NSString *descriptionText;
@property (nullable, nonatomic, retain) NSNumber *distance;
@property (nullable, nonatomic, retain) NSNumber *elevation;
@property (nullable, nonatomic, retain) NSString *identifier;
@property (nullable, nonatomic, retain) NSNumber *latitude;
@property (nullable, nonatomic, retain) NSNumber *longitude;
@property (nullable, nonatomic, retain) NSString *municipality;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *url;
@property (nullable, nonatomic, retain) NSSet<Checkin *> *checkins;
@property (nullable, nonatomic, retain) NSOrderedSet<DntImage *> *images;
@property (nullable, nonatomic, retain) NSSet<Project *> *projects;

@end

@interface Place (CoreDataGeneratedAccessors)

- (void)addCheckinsObject:(Checkin *)value;
- (void)removeCheckinsObject:(Checkin *)value;
- (void)addCheckins:(NSSet<Checkin *> *)values;
- (void)removeCheckins:(NSSet<Checkin *> *)values;

- (void)insertObject:(DntImage *)value inImagesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromImagesAtIndex:(NSUInteger)idx;
- (void)insertImages:(NSArray<DntImage *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeImagesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInImagesAtIndex:(NSUInteger)idx withObject:(DntImage *)value;
- (void)replaceImagesAtIndexes:(NSIndexSet *)indexes withImages:(NSArray<DntImage *> *)values;
- (void)addImagesObject:(DntImage *)value;
- (void)removeImagesObject:(DntImage *)value;
- (void)addImages:(NSOrderedSet<DntImage *> *)values;
- (void)removeImages:(NSOrderedSet<DntImage *> *)values;

- (void)addProjectsObject:(Project *)value;
- (void)removeProjectsObject:(Project *)value;
- (void)addProjects:(NSSet<Project *> *)values;
- (void)removeProjects:(NSSet<Project *> *)values;

@end

NS_ASSUME_NONNULL_END
