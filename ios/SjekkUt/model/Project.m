//
//  Project.m
//
//
//  Created by Henrik Hartz on 26/07/16.
//
//

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

    if ([json objectForKey:@"steder"] != nil)
    {
        NSMutableOrderedSet *places = [NSMutableOrderedSet orderedSet];
        for (NSDictionary *aPlaceDict in json[@"steder"])
        {
            Place *aPlace = [Place insertOrUpdate:aPlaceDict];
            [places addObject:aPlace];
        }
        self.places = places;
    }
}

- (void)updateDistance
{
    for (Place *place in self.places)
    {
        [place updateDistance];
    }
    [model save];
}

@end
