//
//  Summit+Extension.h
//  SjekkUt
//
//  Created by Henrik Hartz on 04/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "Summit.h"

#import <CoreLocation/CoreLocation.h>

@class UIView;

@interface Summit (Extension)

@property (readonly) BOOL haveCheckedIn;
@property (readonly) NSString *checkinTimeAgo;
@property (readonly) NSString *distanceDescription;
@property (readonly) NSString *elevationDescription;
@property (readonly) NSString *checkinCountDescription;
@property (readonly) NSURL *imageURL;
@property (setter=setSummitLocation:) CLLocation *summitLocation;

+ (Summit *)insertOrUpdate:(NSDictionary *)json;
+ (Summit *)findWithId:(id)identifier;
+ (Summit *)mock;
+ (NSArray *)allSummits;

- (NSString *)checkinTimeAgo;
- (NSURL *)mapURLForView:(UIView *)view;
- (Checkin *)lastCheckin;
- (void)updatePlacesDistance;
- (void)updateStatistics:(NSDictionary *)json;
- (BOOL)canCheckIn;
- (BOOL)canCheckinTime;
- (BOOL)canCheckinDistance;

@end
