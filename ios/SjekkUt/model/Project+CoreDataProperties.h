//
//  Project+CoreDataProperties.h
//  SjekkUt
//
//  Created by Henrik Hartz on 24/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Project.h"

NS_ASSUME_NONNULL_BEGIN

@interface Project (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *distance;
@property (nullable, nonatomic, retain) NSString *identifier;
@property (nullable, nonatomic, retain) NSString *infoUrl;
@property (nullable, nonatomic, retain) NSNumber *isParticipating;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSNumber *progress;
@property (nullable, nonatomic, retain) NSDate *start;
@property (nullable, nonatomic, retain) NSDate *stop;
@property (nullable, nonatomic, retain) NSNumber *isHidden;
@property (nullable, nonatomic, retain) NSOrderedSet<DntGroup *> *groups;
@property (nullable, nonatomic, retain) NSOrderedSet<DntImage *> *images;
@property (nullable, nonatomic, retain) NSOrderedSet<Place *> *places;
@property (nullable, nonatomic, retain) DntUser *user;

@end

@interface Project (CoreDataGeneratedAccessors)

- (void)insertObject:(DntGroup *)value inGroupsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromGroupsAtIndex:(NSUInteger)idx;
- (void)insertGroups:(NSArray<DntGroup *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeGroupsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInGroupsAtIndex:(NSUInteger)idx withObject:(DntGroup *)value;
- (void)replaceGroupsAtIndexes:(NSIndexSet *)indexes withGroups:(NSArray<DntGroup *> *)values;
- (void)addGroupsObject:(DntGroup *)value;
- (void)removeGroupsObject:(DntGroup *)value;
- (void)addGroups:(NSOrderedSet<DntGroup *> *)values;
- (void)removeGroups:(NSOrderedSet<DntGroup *> *)values;

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

- (void)insertObject:(Place *)value inPlacesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPlacesAtIndex:(NSUInteger)idx;
- (void)insertPlaces:(NSArray<Place *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePlacesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPlacesAtIndex:(NSUInteger)idx withObject:(Place *)value;
- (void)replacePlacesAtIndexes:(NSIndexSet *)indexes withPlaces:(NSArray<Place *> *)values;
- (void)addPlacesObject:(Place *)value;
- (void)removePlacesObject:(Place *)value;
- (void)addPlaces:(NSOrderedSet<Place *> *)values;
- (void)removePlaces:(NSOrderedSet<Place *> *)values;

@end

NS_ASSUME_NONNULL_END
