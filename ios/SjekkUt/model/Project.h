//
//  Project.h
//
//
//  Created by Henrik Hartz on 26/07/16.
//
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "DntGroup.h"
#import "DntImage.h"
#import "EntityScaffold.h"
#import "Place.h"

NS_ASSUME_NONNULL_BEGIN

@interface Project : EntityScaffold

+ (NSFetchRequest *)fetchRequest;
+ (instancetype)insertOrUpdate:(id)jsonOrId;
+ (NSArray *)allParticipating;

- (void)updateDistance;
- (void)updatePlacesDistance;
//- (void)updateHasCheckin;
- (Place *)findNearest;
- (NSString *)progressDescriptionLong;
- (NSString *)progressDescriptionShort;
- (NSURL *)backgroundImageURLforSize:(CGSize)aSize;
- (NSURL *)foregroundImageURLforSize:(CGSize)aSize;
- (NSString *)distanceDescription;
- (NSString *)countyMunicipalityDescription;
+ (instancetype)findWithId:(id)identifier;

@end

NS_ASSUME_NONNULL_END

#import "Project+CoreDataProperties.h"
