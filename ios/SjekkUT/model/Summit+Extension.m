//
//  Summit+Extension.m
//  SjekkUt
//
//  Created by Henrik Hartz on 04/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "Backend.h"
#import "Challenge+Extension.h"
#import "Checkin+Extension.h"
#import "CheckinStatistics+Extension.h"
#import "Defines.h"
#import "Location.h"
#import "ModelController.h"
#import "Summit+Extension.h"

#define ARC4RANDOM_MAX 0x100000000

@implementation Summit (Extension)

- (void)setSummitLocation:(CLLocation *)_location
{
    self.latitude = @(_location.coordinate.latitude);
    self.longitude = @(_location.coordinate.longitude);
    self.elevation = @(_location.altitude);
}

- (CLLocation *)summitLocation
{
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(self.latitude.doubleValue, self.longitude.doubleValue);

    return [[CLLocation alloc] initWithCoordinate:coordinate
                                         altitude:self.elevation.doubleValue
                               horizontalAccuracy:10
                                 verticalAccuracy:10
                                        timestamp:[NSDate date]];
}

- (BOOL)haveCheckedIn
{
    return self.checkins.count > 0;
}

- (NSString *)checkinTimeAgo;
{
    if (self.haveCheckedIn)
    {
        Checkin *checkin = [self lastCheckin];
        NSString *timeAgo = checkin.timeAgo;
        return timeAgo;
    }
    return nil;
}

- (Checkin *)lastCheckin
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date"
                                                           ascending:YES];
    NSArray *sorts = @[ sort ];
    NSArray *sortedCheckins = [self.checkins sortedArrayUsingDescriptors:sorts];
    Checkin *checkin = [sortedCheckins lastObject];
    return checkin;
}

- (BOOL)canCheckIn
{
    return [self canCheckinTime] && [self canCheckinDistance];
}

- (BOOL)canCheckinTime
{
    if (self.lastCheckin == nil)
    {
        return YES;
    }

    NSTimeInterval timeSinceLastCheckin = [[NSDate date] timeIntervalSinceDate:self.lastCheckin.date];
    NSLog(@"time since last: %f", timeSinceLastCheckin);
    return timeSinceLastCheckin > SjekkUtCheckinTimeLimit;
}

- (BOOL)canCheckinDistance
{
    if (locationBackend.currentLocation == nil)
    {
        return NO;
    }
    return [locationBackend.currentLocation distanceFromLocation:self.summitLocation] < SjekkUtCheckinDistanceLimit;
}

#pragma mark initialization

+ (Summit *)insertOrUpdate:(NSDictionary *)json
{
    NSString *identifier = [NSString stringWithFormat:@"%@", json[@"id"]];
    Summit *theSummit = [Summit findWithId:identifier];

    if (!theSummit)
    {
        theSummit = [Summit insert];
    }

    NSAssert(theSummit != nil, @"Unable to aquire new or existing object");

    [theSummit update:json];

    return theSummit;
}

+ (Summit *)findWithId:(id)identifier
{
    NSFetchRequest *fetch = [[self class] fetch];
    fetch.predicate = [NSPredicate predicateWithFormat:@"identifier = %@", identifier];
    NSError *error = nil;
    Summit *theSummit = [[model.managedObjectContext executeFetchRequest:fetch
                                                                   error:&error]
        lastObject];
    if (error)
    {
        NSLog(@"failed fetching: %@", error);
    }
    return theSummit;
}

- (void)update:(NSDictionary *)json
{
    if (json.count != 9)
        NSLog(@"!!! unhandled JSON keys !!!");

    self.identifier = [NSString stringWithFormat:@"%@", json[@"id"]];
    self.name = json[@"name"];
    self.countyName = json[@"county"];
    double lat = [json[@"location"][@"Lat"] doubleValue];
    double lng = [json[@"location"][@"Lng"] doubleValue];
    double alt = [json[@"height"] doubleValue];
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, lng);
    CLLocation *loc = [[CLLocation alloc] initWithCoordinate:coordinate
                                                    altitude:alt
                                          horizontalAccuracy:10
                                            verticalAccuracy:10
                                                   timestamp:[NSDate date]];
    self.summitLocation = loc;
    self.imageUrl = json[@"iconUrl"];
    self.typeName = @"24 topper";
    self.information = json[@"description"];
    self.checkinCount = json[@"checkinCount"];
    self.infoUrl = json[@"infoUrl"];
    self.hidden = @NO;

    // ensure that a summit at least sorts under the 'no challenge' header
    static Challenge *emptyChallenge = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *emptyJSON =
            @{
                @"id" : @"empty-challenge",
                @"title" : @"No challenge",
                @"url" : @"",
                @"logoUrl" : @"",
                @"footerUrl" : @"",
                @"validFrom" : [[NSDateFormatter instance] stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]],
                @"validTo" : [[NSDateFormatter instance] stringFromDate:[NSDate dateWithTimeIntervalSinceNow:DBL_MAX]],
                @"joined" : @NO
            };
        emptyChallenge = [Challenge insertOrUpdate:emptyJSON];
    });
    if (!self.challenge)
    {
        self.challenge = emptyChallenge;
    }
}

- (void)updateStatistics:(NSDictionary *)json
{
    if (!json)
        return;
    CheckinStatistics *statistics = self.statistics;
    if (!statistics)
    {
        statistics = [CheckinStatistics insert];
    }
    [statistics update:json];
    [self setStatistics:statistics];
}

+ (Summit *)mock
{
    Summit *_mock = [[Summit alloc] initWithEntity:self.entity
                    insertIntoManagedObjectContext:nil];

    _mock.identifier = [@(random()) stringValue];
    _mock.name = @"Galdhøpiggen";
    _mock.latitude = @61.6364962;
    _mock.longitude = @8.312417800000048;
    _mock.typeName = @"Topp";
    _mock.countyName = @"Lom";
    _mock.imageUrl = @"http://r-ec.bstatic.com/images/hotel/square128/402/40238374.jpg";
    _mock.information = @"Galdhøpiggen is the highest mountain in Norway, Scandinavia and Northern Europe, at 2469 m above sea level. It is located within the municipality of Lom, in the Jotunheimen mountain area.";
    _mock.checkinCount = @0;

    // credit http://stackoverflow.com/a/6529063/50830
    double maxRange = 2000.0;
    double minRange = 0.0;
    double elevation = ((double)arc4random() / ARC4RANDOM_MAX) * (maxRange - minRange) + minRange;
    _mock.elevation = @(elevation);

    return _mock;
}

#pragma mark database

+ (NSEntityDescription *)entity
{
    return [NSEntityDescription entityForName:@"Summit"
                       inManagedObjectContext:model.managedObjectContext];
}

+ (NSArray *)allSummits
{
    NSFetchRequest *fetchRequest = [self fetch];
    NSError *err;
    NSArray *allSummits = [[model managedObjectContext] executeFetchRequest:fetchRequest error:&err];
    if (err)
    {
        NSLog(@"allSummits failed: %@", err);
        return @[];
    }
    return allSummits;
}

#pragma mark calculated / transient attributes

- (NSNumberFormatter *)formatter
{
    static NSNumberFormatter *_formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _formatter = [[NSNumberFormatter alloc] init];
        _formatter.groupingSize = 1;
    });
    return _formatter;
}

- (NSString *)distanceDescription
{
    if (self.distance.intValue == -1)
        return @"";

    NSString *unit = @"km";

    NSUInteger distance = self.distance.unsignedIntegerValue;
    if (distance < 1000)
    {
        unit = @"m";
    }
    else
    {
        distance /= 1000;
    }
    return [NSString stringWithFormat:@"%ld %@",
                                      (long)distance, unit];
}

- (NSString *)elevationDescription
{
    return [NSString stringWithFormat:@"%@ moh.", [[self formatter] stringFromNumber:self.elevation]];
}

- (NSURL *)imageURL
{
    return [NSURL URLWithString:self.imageUrl];
}

- (NSURL *)mapURLForView:(UIView *)view
{
    //  CGFloat uiScale = [UIScreen mainScreen].scale;
    CGFloat maxWidth = 640.0f;
    CGFloat pixelScale = maxWidth / view.frame.size.width;
    CGFloat width = view.frame.size.width * pixelScale;
    CGFloat height = view.frame.size.height * pixelScale;

    NSString *apiKey = @"AIzaSyDSn0vYqHUuazbG5PPIYm-HYu-Wi2qbcCM";
    NSMutableString *urlString = [@"https://maps.googleapis.com/maps/api/staticmap" mutableCopy];
    [urlString appendFormat:@"?center=%@,%@&zoom=%.f&maptype=terrain&", self.latitude, self.longitude, SjekkUtMapZoomLevel];
    [urlString appendFormat:@"size=%@x%@&scale=2&key=%@&", @((int)width), @((int)height), apiKey];
    [urlString appendFormat:@"markers=%@,%@", self.latitude, self.longitude];
    if (locationBackend.currentLocation && self.distance.intValue < 1000 && [[NSUserDefaults standardUserDefaults] boolForKey:SjekkUtShowOwnLocationOnMap])
    {
        [urlString appendString:@"&markers=color:green%7C"];
        [urlString appendFormat:@"%@,%@", @(locationBackend.currentLocation.coordinate.latitude), @(locationBackend.currentLocation.coordinate.longitude)];
    }
    return [NSURL URLWithString:urlString];
}

- (NSString *)checkinCountDescription
{
    return (self.checkinCount.integerValue == 1 ? [NSString stringWithFormat:NSLocalizedString(@"Summited %@ time", @"summit count label singular"), self.checkinCount]
                                                : [NSString stringWithFormat:NSLocalizedString(@"Summited %@ times", @"summit count label plural"), self.checkinCount]);
}

- (void)updateDistance
{
    NSNumber *newDistance = @([self.summitLocation distanceFromLocation:locationBackend.currentLocation]);
    if (![self.distance isEqualToNumber:newDistance])
    {
        self.distance = newDistance;
    }
}

@end
