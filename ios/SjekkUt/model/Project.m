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
    Project *theEntity = [self findWithId:identifier];

    if (!theEntity)
    {
        theEntity = [self insert];
        theEntity.identifier = identifier;
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
    if ([self.identifier isEqual:@"57974036b565590001a98884"])
    {
        NSLog(@"break");
    }
    setIfNotEqual(self.name, json[@"navn"]);

    NSArray *coordinates = nil;
    if ((coordinates = json[@"geojson"][@"coordinates"]) != nil)
    {
        setIfNotEqual(self.latitude, @([[coordinates objectAtIndex:1] doubleValue]));
        setIfNotEqual(self.longitude, @([[coordinates objectAtIndex:0] doubleValue]));
    }
    [self updateDistance];

    [self parsePlaces:json[@"steder"]];
    [self parseImages:json[@"bilder"]];
}

#pragma mark images

- (void)parsePlaces:(NSArray *)places
{
    NSMutableOrderedSet *orderedPlaces = [NSMutableOrderedSet orderedSet];

    for (NSDictionary *aPlaceDict in places)
    {
        Place *aPlace = [Place insertOrUpdate:aPlaceDict];
        [orderedPlaces addObject:aPlace];
    }

    if ([orderedPlaces.set isEqualToSet:self.places.set])
    {
        return;
    }
    else
    {
        self.places = orderedPlaces;
        [self updateHasCheckin];
    }
}

- (void)parseImages:(NSArray *)images
{
    NSMutableOrderedSet *orderedImages = [NSMutableOrderedSet orderedSet];
    if ([self.identifier isEqual:@"57b2f2c04ba3bf00011bb695"])
    {
        NSLog(@"asdf");
    }
    for (NSDictionary *anImageDict in images)
    {
        DntImage *anImage = [DntImage insertOrUpdate:anImageDict];
        [orderedImages addObject:anImage];
    }

    if ([orderedImages.set isEqualToSet:self.images.set])
    {
        return;
    }

    self.images = orderedImages;
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
    NSNumber *newDistance = @(round([self.projectLocation distanceFromLocation:locationBackend.currentLocation]));
    if (self.latitude != nil && self.longitude != nil)
    {
        setIfNotEqual(self.distance, newDistance);
    }
    else
    {
        setIfNotEqual(self.distance, @(DBL_MIN));
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
    setIfNotEqual(self.hasCheckins, @(self.progress.doubleValue > 0.0));
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
