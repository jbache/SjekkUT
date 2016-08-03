//
//  Place.h
//  SjekkUt
//
//  Created by Henrik Hartz on 27/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "Checkin.h"
#import "EntityScaffold.h"

@class Project;

NS_ASSUME_NONNULL_BEGIN

@interface Place : EntityScaffold

+ (NSFetchRequest *)fetchRequest;
+ (instancetype)insertOrUpdate:(NSDictionary *)json;
+ (instancetype)findWithId:(id)identifier;

- (void)updateDistance;
- (NSString *)distanceDescription;
- (NSString *_Nonnull)elevationDescription;
- (NSString *)checkinCountDescription;
- (Checkin *)lastCheckin;

@end

NS_ASSUME_NONNULL_END

#import "Place+CoreDataProperties.h"
