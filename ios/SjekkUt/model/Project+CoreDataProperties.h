//
//  Project+CoreDataProperties.h
//  SjekkUt
//
//  Created by Henrik Hartz on 03/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Project.h"

NS_ASSUME_NONNULL_BEGIN

@interface Project (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *identifier;
@property (nullable, nonatomic, retain) NSString *infoUrl;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSOrderedSet<DntImage *> *images;
@property (nullable, nonatomic, retain) NSOrderedSet<Place *> *places;

@end

@interface Project (CoreDataGeneratedAccessors)

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
