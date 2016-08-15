//
//  DntImage+CoreDataProperties.h
//  SjekkUt
//
//  Created by Henrik Hartz on 15/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "DntImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface DntImage (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *identifier;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *naming;
@property (nullable, nonatomic, retain) NSSet<Place *> *places;
@property (nullable, nonatomic, retain) Project *projects;
@property (nullable, nonatomic, retain) NSSet<DntImageSize *> *sizes;

@end

@interface DntImage (CoreDataGeneratedAccessors)

- (void)addPlacesObject:(Place *)value;
- (void)removePlacesObject:(Place *)value;
- (void)addPlaces:(NSSet<Place *> *)values;
- (void)removePlaces:(NSSet<Place *> *)values;

- (void)addSizesObject:(DntImageSize *)value;
- (void)removeSizesObject:(DntImageSize *)value;
- (void)addSizes:(NSSet<DntImageSize *> *)values;
- (void)removeSizes:(NSSet<DntImageSize *> *)values;

@end

NS_ASSUME_NONNULL_END
