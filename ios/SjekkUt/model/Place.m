//
//  Place.m
//  SjekkUt
//
//  Created by Henrik Hartz on 27/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "Defines.h"
#import "Location.h"
#import "ModelController.h"
#import "Place.h"
#import "Project.h"

@implementation Place

+ (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *aFetchRequest = [self.class fetch];
    aFetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO] ];
    return aFetchRequest;
}

+ (instancetype)insertOrUpdate:(id)json
{
    NSString *identifier = nil;
    if ([json isKindOfClass:[NSDictionary class]])
    {
        identifier = json[@"_id"];
    }
    else if ([json isKindOfClass:[NSString class]])
    {
        identifier = json;
    }

    Place *theEntity = [self findWithId:identifier];

    if (!theEntity && identifier != nil)
    {
        theEntity = [self insert];
        theEntity.identifier = identifier;
    }

    NSAssert(theEntity != nil, @"Unable to aquire new or existing object");

    if ([json isKindOfClass:[NSDictionary class]])
    {
        [theEntity update:json];
    }

    return theEntity;
}

+ (instancetype)findWithId:(id)identifier
{
    NSFetchRequest *fetch = [[self class] fetch];
    fetch.predicate = [NSPredicate predicateWithFormat:@"identifier = %@", identifier];
    NSError *error = nil;
    id theEntity = [[model.managedObjectContext executeFetchRequest:fetch
                                                              error:&error] lastObject];
    if (error)
    {
        NSLog(@"failed fetching: %@", error);
    }
    return theEntity;
}

- (void)update:(NSDictionary *)json
{
    setIfNotEqual(self.name, json[@"navn"]);
    setIfNotEqual(self.municipality, json[@"kommune"]);
    setIfNotEqual(self.county, json[@"fylke"]);
    setIfNotEqual(self.descriptionText, json[@"beskrivelse"]);
    [self updateCoordinates:[json valueForKeyPath:@"geojson.coordinates"]];
    [self updateImages:json[@"bilder"]];
}

#pragma mark images

- (void)updateImages:(NSArray *)images
{
    NSMutableOrderedSet *orderedImages = [NSMutableOrderedSet orderedSet];
    if (images != nil && images.count > 0)
    {
        for (id imageDict in images)
        {
            DntImage *anImage = [DntImage insertOrUpdate:imageDict];
            [orderedImages addObject:anImage];
        }
    }

    if (![self.images isEqualToOrderedSet:orderedImages])
    {
        self.images = orderedImages;
    }
}

- (NSURL *)foregroundImageURLforSize:(CGSize)aSize
{
    if (self.images.count > 0)
    {
        DntImage *theImage = [self.images objectAtIndex:0];
        return [theImage URLforSize:aSize];
    }
    return nil;
}

#pragma mark location

- (void)updateCoordinates:(NSArray *)coordinates
{
    if (coordinates != nil)
    {
        switch (coordinates.count)
        {
            case 3:
                setIfNotEqual(self.elevation, @([[coordinates objectAtIndex:2] doubleValue]));
            case 2:
                setIfNotEqual(self.latitude, @([[coordinates objectAtIndex:1] doubleValue]));
            case 1:
                setIfNotEqual(self.longitude, @([[coordinates objectAtIndex:0] doubleValue]));
        }
    }
    [self updateDistance];
}

- (void)updateDistance
{
    // don't update distance if current location is unknown
    if (locationBackend.currentLocation == nil)
    {
        return;
    }

    NSNumber *newDistance = @(round([self.summitLocation distanceFromLocation:locationBackend.currentLocation]));
    if (self.latitude != nil && self.longitude != nil)
    {
        setIfNotEqual(self.distance, newDistance);
    }
    else
    {
        setIfNotEqual(self.distance, @(DBL_MAX));
    }
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

#pragma mark - checkin

- (Checkin *)lastCheckin
{
    DntUser *aUser = [DntUser currentUser];
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"user == %@", aUser];
    NSSet *filteredCheckins = [self.checkins filteredSetUsingPredicate:filter];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date"
                                                           ascending:YES];
    NSArray *sorts = @[ sort ];
    NSArray *sortedCheckins = [filteredCheckins sortedArrayUsingDescriptors:sorts];
    Checkin *checkin = [sortedCheckins lastObject];
    return checkin;
}

- (BOOL)canCheckIn
{
    return self.canCheckinTime && self.canCheckinDistance;
}

- (BOOL)canCheckinTime
{
    Checkin *aLastCheckin = self.lastCheckin;
    if (aLastCheckin == nil)
    {
        return YES;
    }

    NSTimeInterval timeSinceLastCheckin = [[NSDate date] timeIntervalSinceDate:aLastCheckin.date];
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

#pragma mark - map

- (NSURL *)mapURLForView:(UIView *)view withKey:(nonnull NSString *)apiKey
{
    //  CGFloat uiScale = [UIScreen mainScreen].scale;
    CGFloat maxWidth = 640.0f;
    CGFloat pixelScale = maxWidth / view.frame.size.width;
    CGFloat width = view.frame.size.width * pixelScale;
    CGFloat height = view.frame.size.height * pixelScale;

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

#pragma mark - convenience descriptions

- (NSString *)distanceDescription
{
    if (self.distance.doubleValue == DBL_MAX)
        return @"";

    NSString *unit = @"km";

    CLLocationDistance distance = self.distance.doubleValue;
    if (distance < 1000)
    {
        unit = @"m";
    }
    else
    {
        distance /= 1000;
    }
    return [NSString stringWithFormat:@"%ld %@", (long)distance, unit];
}

- (NSString *)elevationDescription
{
    NSInteger elevation = self.elevation.integerValue;
    if (elevation > 0)
    {
        return [NSString stringWithFormat:@"%ld moh.", (long)self.elevation.integerValue];
    }
    return @"";
}

- (NSString *)checkinCountDescription
{
    NSInteger checkinCount = self.checkins.count;
    return (checkinCount == 1 ? [NSString stringWithFormat:NSLocalizedString(@"Summited %ld time", @"summit count label singular"), (long)checkinCount]
                              : [NSString stringWithFormat:NSLocalizedString(@"Summited %ld times", @"summit count label plural"), (long)checkinCount]);
}

- (NSString *)checkinTimeAgo;
{
    if (self.checkins.count > 0)
    {
        Checkin *checkin = [self lastCheckin];
        NSString *timeAgo = checkin.timeAgo;
        return timeAgo;
    }
    return nil;
}

- (NSString *)checkinDescription
{
    NSMutableString *aCheckinDescription = [@"" mutableCopy];
    //    if (self.statistics != nil)
    //    {
    //        [checkinDescription appendFormat:@"%@\n\n", self.summit.statistics.verboseDescription];
    //    }

    if ([self canCheckIn])
    {
        [aCheckinDescription appendString:NSLocalizedString(@"You can check in.", @"can check in")];
    }
    else
    {
        BOOL checkinTime = self.canCheckinTime;
        BOOL checkinDistance = self.canCheckinDistance;
        if (!checkinTime && !checkinDistance)
        {
            [aCheckinDescription appendString:NSLocalizedString(@"You have to be 200 meter from the summit and wait 24 hours before you can check in.", @"can't check in time and distance")];
        }
        else if (!checkinTime)
        {
            [aCheckinDescription appendString:NSLocalizedString(@"You have to wait 24 hours before you can check in.", @"can't check in time")];
        }
        else if (!checkinDistance)
        {
            [aCheckinDescription appendString:NSLocalizedString(@"You have to be 200 meter from the summit before you can check in.", @"can't check in distance")];
        }
    }

    return aCheckinDescription;
}

@end
