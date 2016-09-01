//
//  Location.m
//  SjekkUt
//
//  Created by Henrik Hartz on 05/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "Defines.h"
#import "Location.h"

@interface NSString (contains)
- (BOOL)contains:(NSString *)str;
@end
@implementation NSString (contains)
- (BOOL)contains:(NSString *)str;
{
    return [self rangeOfString:str].location != NSNotFound;
}
@end

@interface Location () <CLLocationManagerDelegate>

@property (copy, nonatomic) void (^authorizedHandler)(void);

@end

@implementation Location
{
    BOOL updateEnabled;
    BOOL showingDialog;
    UIAlertView *permissionRequest;
};

@synthesize currentLocation;
@synthesize locationManager;
@synthesize updateHandler;
@synthesize minAccuracy;
@synthesize singleUpdateInProgress;

- (id)init
{
    self = [super init];
    if (!self)
        return nil;

    locationManager = [[CLLocationManager alloc] init];
    locationManager.distanceFilter = DISTANCE_FILTER / 4;
    locationManager.delegate = self;
    locationManager.pausesLocationUpdatesAutomatically = YES;
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    locationManager.activityType = CLActivityTypeFitness;

    [defaultNotifyer addObserver:self selector:@selector(locationDidTimeOut:)
                            name:SjekkUtTimeoutNotification
                          object:nil];

    currentLocation = nil;
    minAccuracy = DISTANCE_FILTER;

    return self;
}

+ (Location *)instance
{
    static Location *_instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[Location alloc] init];
    });

    return _instance;
}

#pragma mark - permissions

- (BOOL)checkPermissions:(void (^)(void))authorizedHandler
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    self.authorizedHandler = authorizedHandler;

    switch (status)
    {
        case kCLAuthorizationStatusNotDetermined:
            [self askForPermission];
            break;

        case kCLAuthorizationStatusDenied:
            [self notifyMissingPermission];
            break;

        case kCLAuthorizationStatusRestricted:
            [self notifyFailureToLocate];
            break;

        default:
            [self dispatchAuthorizedHandler];
            return YES;
    }

    return NO;
}

- (void)dispatchAuthorizedHandler
{
    if (self.authorizedHandler)
    {
        self.authorizedHandler();
    }
}

- (void)askForPermission
{
    if (showingDialog)
        return;

    showingDialog = YES;
    permissionRequest = [[UIAlertView alloc] init];
    permissionRequest.title = NSLocalizedString(@"Allow using location", @"title for location request");
    permissionRequest.message = NSLocalizedString(@"This app requires using Location services. Is it OK to request permissions for using your device position?", @"message for location request");
    permissionRequest.cancelButtonIndex = [permissionRequest addButtonWithTitle:NSLocalizedString(@"No", @"cancel button title for location request")];
    [permissionRequest addButtonWithTitle:NSLocalizedString(@"Yes!", @"Ok button title for location request")];
    permissionRequest.delegate = self;

    [permissionRequest show];
}

- (void)notifyMissingPermission
{
    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.title = NSLocalizedString(@"Unable to locate", @"title for missing location");
    alert.message = NSLocalizedString(@"This app is not authorized to use Location services. Please open Settings and enable location services for this app.", @"message for missing location");
    alert.cancelButtonIndex = [alert addButtonWithTitle:NSLocalizedString(@"OK", @"cancel button title for restricted location")];
    [alert show];
}

- (void)notifyFailureToLocate
{
    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.title = NSLocalizedString(@"Unable to locate", @"title for restricted location");
    alert.message = NSLocalizedString(@"This app is not authorized to use Location services, possibly because of parental controls", @"message for restricted location");
    alert.cancelButtonIndex = [alert addButtonWithTitle:NSLocalizedString(@"OK", @"cancel button title for restricted location")];
    [alert show];
}

#pragma mark - UIAlertview
- (void)showError:(NSString *)title message:(NSString *)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    showingDialog = NO;

    if (buttonIndex == alertView.cancelButtonIndex)
    {
        return;
    }

    [self dispatchAuthorizedHandler];
}

#pragma mark - location

- (void)startUpdate
{
    updateEnabled = YES;

    __weak typeof(self) weakSelf = self;
    [locationBackend checkPermissions:^{
#if TESTING
        CLLocation *loc = [[CLLocation alloc] initWithLatitude:59.9431938
                                                     longitude:10.7167756];
        [weakSelf locationManager:weakSelf.locationManager didUpdateLocations:@[ loc ]];
#else
        switch ([CLLocationManager authorizationStatus])
        {
            case kCLAuthorizationStatusNotDetermined:
                if ([weakSelf.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
                {
                    [weakSelf.locationManager requestWhenInUseAuthorization];
                }
                else
                {
                    [weakSelf.locationManager startUpdatingLocation];
                }
                break;
            case kCLAuthorizationStatusAuthorizedWhenInUse:
            case kCLAuthorizationStatusAuthorizedAlways:
                [weakSelf.locationManager startUpdatingLocation];
                break;

            case kCLAuthorizationStatusRestricted:;
            case kCLAuthorizationStatusDenied:
                [weakSelf stopUpdate];
                // TOOD: need additional error dialog here?
                //          [backend showError:NSLocalizedString(@"Unable to locate", @"locate permission error message")
                //                     message:NSLocalizedString(@"Unable to locate you. This can occur if you didn't allow using location services, or if your device has parental controls.", @"locate permission error message")];
                break;
        }
#endif
    }];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    if (!updateEnabled)
        return;

    [self willChangeValueForKey:@"currentLocation"];
    currentLocation = locations.firstObject;
    [self didChangeValueForKey:@"currentLocation"];

    // continue looking if the accuracy is too low
    if (currentLocation.horizontalAccuracy > minAccuracy)
    {
        return;
    }

    [NSNotificationCenter.defaultCenter postNotificationName:kSjekkUtNotificationLocationChanged object:nil];

    if (self.updateHandler)
    {
        self.updateHandler(currentLocation);
    }

    // if we're doing only a single update we can stop now
    if (singleUpdateInProgress)
    {
        self.updateHandler = nil;
        [self stopUpdate];
    }
}

- (void)stopUpdate
{
    updateEnabled = NO;
    [locationManager stopUpdatingLocation];
    self.singleUpdateInProgress = NO;
}

- (void)locationManager:(CLLocationManager *)manager
    didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status)
    {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            if (self.authorizedHandler)
            {
                self.authorizedHandler();
                self.authorizedHandler = nil;
            }
            break;

        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self showError:NSLocalizedString(@"Positioning Failure", @"title for generic location failure")
            message:error.localizedDescription];
    //    [self stopUpdate];
}

- (void)getSingleUpdate:(void (^)(CLLocation *location))anUpdateHandler
{
    if (!singleUpdateInProgress)
    {
        singleUpdateInProgress = YES;
        self.updateHandler = anUpdateHandler;
        [self startUpdate];
    }
}

- (void)locationDidTimeOut:(NSNotification *)notification
{
    singleUpdateInProgress = NO;
    [self stopUpdate];

    NSString *text = @"";
    switch ([CLLocationManager authorizationStatus])
    {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            text = NSLocalizedString(
                @"Could not get a location. Make sure you are in view of the sky to allow GPS positioning to take place.",
                @"location timeout notification text");
            break;
        }
        default:
        {
            text = NSLocalizedString(
                @"Could not get a location. Make sure you have authorized the use of location services.",
                @"location timeout notification text");
            break;
        }
    }

    [self showError:NSLocalizedString(@"Unable to Locate", @"location timeout title")
            message:text];
}

@end
