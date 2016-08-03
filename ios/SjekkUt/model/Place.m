//
//  Place.m
//  SjekkUt
//
//  Created by Henrik Hartz on 27/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

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

+ (instancetype)insertOrUpdate:(NSDictionary *)json
{
    NSString *identifier = [NSString stringWithFormat:@"%@", json[@"_id"]];
    id theEntity = [self findWithId:identifier];

    if (!theEntity)
    {
        theEntity = [self insert];
    }

    NSAssert(theEntity != nil, @"Unable to aquire new or existing object");

    [theEntity update:json];

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
    self.identifier = [NSString stringWithFormat:@"%@", json[@"_id"]];
    self.name = json[@"navn"];
    NSArray *coordinateArray = [json valueForKeyPath:@"geojson.coordinates"];
    switch (coordinateArray.count)
    {
        case 3:
            self.elevation = @([[coordinateArray objectAtIndex:2] doubleValue]);
        case 2:
            self.longitude = @([[coordinateArray objectAtIndex:1] doubleValue]);
        case 1:
            self.latitude = @([[coordinateArray objectAtIndex:0] doubleValue]);
    }
    self.county = json[@"kommune"];
    [self updateDistance];
}

- (void)updateDistance
{
    NSNumber *newDistance = @([self.summitLocation distanceFromLocation:locationBackend.currentLocation]);
    if (![self.distance isEqualToNumber:newDistance])
    {
        self.distance = newDistance;
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

- (Checkin *)lastCheckin
{
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date"
                                                           ascending:YES];
    NSArray *sorts = @[ sort ];
    NSArray *sortedCheckins = [self.checkins sortedArrayUsingDescriptors:sorts];
    Checkin *checkin = [sortedCheckins lastObject];
    return checkin;
}

#pragma mark - convenience descriptions

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

@end
