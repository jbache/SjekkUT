//
//  Project.m
//
//
//  Created by Henrik Hartz on 26/07/16.
//
//

#import "DntImage.h"
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
    self.places = [self parsePlaces:json[@"steder"]];
    self.images = [self parseImages:json[@"bilder"]];
}

- (NSOrderedSet *)parsePlaces:(NSArray *)places
{
    if (places == nil)
    {
        return nil;
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
    if (images == nil)
    {
        return nil;
    }

    NSMutableOrderedSet *orderedImages = [NSMutableOrderedSet orderedSet];

    for (NSDictionary *anImageDict in images)
    {
        DntImage *anImage = [DntImage insertOrUpdate:anImageDict];
        [orderedImages addObject:anImage];
    }

    return orderedImages;
}

#pragma mark distance

- (void)updateDistance
{
    for (Place *place in self.places)
    {
        [place updateDistance];
    }
    [model save];
}

- (Place *)findNearest
{
    for (Place *aPlace in self.places)
    {
        [aPlace updateDistance];
    }
    [model save];

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
    self.hasCheckins = @(self.progress.doubleValue > 0.0);
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

- (NSString *)progressDescription
{
    NSString *formatString = NSLocalizedString(@"You have summited %@ of %@ so far!", "count summits in challenge");
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
