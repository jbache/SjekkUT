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
    self.latitude = @([[coordinateArray firstObject] doubleValue]);
    self.longitude = @([[coordinateArray lastObject] doubleValue]);
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

@end
