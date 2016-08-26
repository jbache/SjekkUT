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
    setIfNotEqual(self.name, json[@"navn"]);
    NSDate *start = [[self dateFormatter] dateFromString:json[@"start"]];
    setIfNotEqual(self.start, start);
    NSDate *stop = [[self dateFormatter] dateFromString:json[@"stopp"]];
    setIfNotEqual(self.stop, stop);

    [self parsePlaces:json[@"steder"]];
    [self parseImages:json[@"bilder"]];
    [self parseGroups:json[@"grupper"]];
    [self updateDistance];
}

- (NSDateFormatter *)dateFormatter
{
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"];
    });
    return _dateFormatter;
}

#pragma mark places

- (void)parsePlaces:(NSArray *)places
{
    NSMutableOrderedSet *orderedPlaces = [NSMutableOrderedSet orderedSet];

    for (NSDictionary *aPlaceDict in places)
    {
        Place *aPlace = [Place insertOrUpdate:aPlaceDict];
        [orderedPlaces addObject:aPlace];
    }

    if (![orderedPlaces.set isEqualToSet:self.places.set])
    {
        self.places = orderedPlaces;
    }

    [self updateHasCheckin];
}

- (NSString *)countyMunicipalityDescription
{
    NSMutableArray *counties = [@[] mutableCopy];
    NSMutableArray *municipalities = [@[] mutableCopy];

    for (Place *aPlace in self.places)
    {
        if (aPlace.county.length > 0)
        {
            [counties addObject:aPlace.county];
        }
        if (aPlace.municipality.length > 0)
        {
            [municipalities addObject:aPlace.municipality];
        }
    }

    NSString *municipalitiesString = [municipalities componentsJoinedByString:@", "];
    NSString *countiesString = [counties componentsJoinedByString:@", "];

    return [NSString stringWithFormat:@"%@%@%@", countiesString, (municipalitiesString.length > 0 && countiesString.length > 0) ? @"/" : @"", municipalitiesString];
}

#pragma mark groups

- (void)parseGroups:(NSArray *)aGroupArray
{
    NSMutableOrderedSet *orderedGroups = [NSMutableOrderedSet orderedSet];

    for (NSDictionary *aGroupDict in aGroupArray)
    {
        DntGroup *aGroup = [DntGroup insertOrUpdate:aGroupDict];
        [orderedGroups addObject:aGroup];
    }

    if ([orderedGroups.set isEqualToSet:self.groups.set])
    {
        return;
    }
    else
    {
        self.groups = orderedGroups;
    }
}

#pragma mark images

- (void)parseImages:(NSArray *)images
{
    NSMutableOrderedSet *orderedImages = [NSMutableOrderedSet orderedSet];

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
    // don't update distance if current location is unknown
    if (locationBackend.currentLocation == nil)
    {
        return;
    }

    // recalculate distance to all places
    [self updatePlacesDistance];

    // find the nearest place within project and use that distance
    NSSortDescriptor *sortDistance = [NSSortDescriptor sortDescriptorWithKey:@"distance" ascending:YES];
    NSArray *sortedPlaces = [self.places sortedArrayUsingDescriptors:@[ sortDistance ]];
    NSArray *filteredPlaces = [sortedPlaces filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"distance > 0"]];
    Place *nearestPlace = [filteredPlaces firstObject];
    if (nearestPlace.latitude != nil && nearestPlace.longitude != nil)
    {
        NSNumber *newDistance = nearestPlace.distance;
        setIfNotEqual(self.distance, newDistance);
    }
    else
    {
        setIfNotEqual(self.distance, @(DBL_MAX));
    }
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
    NSNumber *isParticipating = [NSNumber numberWithBool:(self.progress.doubleValue > 0.0001)];
    setIfNotEqual(self.isParticipating, isParticipating);
    [[NSNotificationCenter defaultCenter] postNotificationName:kSjekkUtNotificationCheckinChanged object:nil];
}

- (NSArray *)checkedInPlaces
{
    NSFetchRequest *fetch = [Place fetch];
    fetch.predicate = [NSPredicate predicateWithFormat:@"%@ in projects AND checkins.@count > 0", self];
    fetch.includesPendingChanges = YES;
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

@end
