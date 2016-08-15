//
//  Project.m
//
//
//  Created by Henrik Hartz on 26/07/16.
//
//

@import Foundation;
@import CoreLocation;

#import "Defines.h"
#import "DntImage.h"
#import "Location.h"
#import "ModelController.h"
#import "Place.h"
#import "Project.h"

@implementation Project

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
    NSArray *coordinates = nil;
    if ((coordinates = json[@"geojson"][@"coordinates"]) != nil)
    {
        self.latitude = @([[coordinates objectAtIndex:1] doubleValue]);
        self.longitude = @([[coordinates objectAtIndex:0] doubleValue]);
    }
    [self updateDistance];

    self.places = [self parsePlaces:json[@"steder"]];
    self.images = [self parseImages:json[@"bilder"]];
}

#pragma mark images

- (NSOrderedSet *)parsePlaces:(NSArray *)places
{
    if (places == nil || places.count == 0)
    {
        return [NSOrderedSet orderedSet];
    }

    NSMutableOrderedSet *orderedPlaces = [NSMutableOrderedSet orderedSet];

    for (NSDictionary *aPlaceDict in places)
    {
        Place *aPlace = [Place insertOrUpdate:aPlaceDict];
        [orderedPlaces addObject:aPlace];
    }

    [self updateHasCheckin];

    return orderedPlaces;
}

- (NSOrderedSet *)parseImages:(NSArray *)images
{
    if (images == nil || images.count == 0)
    {
        return [NSOrderedSet orderedSet];
    }

    NSMutableOrderedSet *orderedImages = [NSMutableOrderedSet orderedSet];

    for (NSDictionary *anImageDict in images)
    {
        DntImage *anImage = [DntImage insertOrUpdate:anImageDict];
        [orderedImages addObject:anImage];
    }

    return orderedImages;
}

- (NSURL *)backgroundImageURLforSize:(CGSize)aSize;
{
    if (self.images.count > 1)
    {
        DntImage *theImage = [self.images objectAtIndex:1];
        return [theImage URLforSize:aSize];
    }
    return nil;
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

#pragma mark distance

- (void)updateDistance
{
    NSNumber *newDistance = @([self.projectLocation distanceFromLocation:locationBackend.currentLocation]);
    if (self.latitude != nil && self.longitude != nil && ![self.distance isEqualToNumber:newDistance])
    {
        self.distance = newDistance;
    }
    else
    {
        self.distance = @(DBL_MIN);
    }
}

- (CLLocation *)projectLocation
{
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(self.latitude.doubleValue, self.longitude.doubleValue);

    return [[CLLocation alloc] initWithCoordinate:coordinate
                                         altitude:0
                               horizontalAccuracy:10
                                 verticalAccuracy:10
                                        timestamp:[NSDate date]];
}

- (void)updatePlacesDistance
{
    [model saveBlock:^{
        for (Place *place in self.places)
        {
            [place updateDistance];
        }
    }];
}

- (NSString *)distanceDescription
{
    if (self.distance.doubleValue <= 0)
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
    return [NSString stringWithFormat:@"%ld %@",
                                      (long)distance, unit];
}

- (Place *)findNearest
{
    [model saveBlock:^{
        for (Place *aPlace in self.places)
        {
            [aPlace updateDistance];
        }
    }];

    NSArray *sorts = @[ [NSSortDescriptor sortDescriptorWithKey:@"distance"
                                                      ascending:NO] ];
    NSArray *places = [self.places sortedArrayUsingDescriptors:sorts];

    Place *aPlace = nil;
    aPlace = [places lastObject];
    return aPlace;
}

#pragma mark checkins / progress

- (void)updateHasCheckin
{
    BOOL oldCheckin = self.hasCheckins.boolValue;
    self.hasCheckins = @(self.progress.doubleValue > 0.0);
    if (oldCheckin != self.hasCheckins.boolValue)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSjekkUtNotificationCheckinChanged object:nil];
    }
}

- (NSArray *)checkedInPlaces
{
    NSFetchRequest *fetch = [Place fetch];
    fetch.predicate = [NSPredicate predicateWithFormat:@"%@ in projects AND checkins.place.@count > 0", self];

    NSError *error = nil;
    NSArray *aResult = [model.managedObjectContext executeFetchRequest:fetch error:&error];
    return aResult;
}

- (NSNumber *)progress
{
    NSArray *checkedInPlaces = [self checkedInPlaces];

    if (checkedInPlaces.count == 0)
    {
        return @(0);
    }

    return @((double)checkedInPlaces.count / (double)self.places.count);
}

- (NSString *)progressDescriptionLong
{
    NSString *formatString = NSLocalizedString(@"You have summited %@ of %@ so far!", "count summits in challenge");
    return [NSString stringWithFormat:formatString, @((double)self.places.count * self.progress.doubleValue), @(self.places.count)];
}

- (NSString *)progressDescriptionShort
{
    NSString *formatString = NSLocalizedString(@"Visited %@ of %@", "count visits in project cell");
    return [NSString stringWithFormat:formatString, @((double)self.places.count * self.progress.doubleValue), @(self.places.count)];
}

- (NSNumber *)hasCheckins
{
    [self willAccessValueForKey:@"hasCheckins"];

    NSNumber *doesHaveCheckins = @(self.progress.doubleValue > 0.0);

    [self didAccessValueForKey:@"hasCheckins"];

    return doesHaveCheckins;
}

@end
