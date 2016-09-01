//
//  Place.h
//  SjekkUt
//
//  Created by Henrik Hartz on 27/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

@import CoreData;
@import UIKit;

#import "Checkin.h"
#import "DntImage.h"
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
- (NSURL *)mapURLForView:(UIView *)view withKey:(NSString *)key;
- (NSURL *)foregroundImageURLforSize:(CGSize)aSize;
- (NSString *)checkinDescription;
- (BOOL)canCheckIn;
- (BOOL)canCheckinTime;

@end

NS_ASSUME_NONNULL_END

#import "Place+CoreDataProperties.h"
