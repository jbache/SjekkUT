//
//  Project+CoreDataProperties.h
//  SjekkUt
//
//  Created by Henrik Hartz on 27/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Project.h"

@class Place;

NS_ASSUME_NONNULL_BEGIN

@interface Project (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *identifier;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSOrderedSet<Place *> *places;

@end

@interface Project (CoreDataGeneratedAccessors)

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
