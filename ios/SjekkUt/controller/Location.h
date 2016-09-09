//
//  Location.h
//  SjekkUt
//
//  Created by Henrik Hartz on 05/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define locationBackend [Location instance]
#define LOCATION_LIMIT 200
#define DISTANCE_FILTER LOCATION_LIMIT / 2

@interface Location : NSObject <UIAlertViewDelegate>

@property (retain, nonatomic) CLLocationManager *locationManager;
@property (retain, nonatomic) CLLocation *currentLocation;
@property (copy, nonatomic) void (^updateHandler)(CLLocation *);
@property NSInteger minAccuracy;
@property BOOL singleUpdateInProgress;

- (BOOL)checkPermissions:(void (^)(void))authorizedHandler;
+ (Location *)instance;

- (void)getSingleUpdate:(void (^)(CLLocation *))updateHandler;
- (void)startUpdate;
- (void)stopUpdate;

@end
