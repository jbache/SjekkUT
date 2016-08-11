//
//  DntImage.m
//  SjekkUt
//
//  Created by Henrik Hartz on 03/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

#import "DntImage.h"
#import "ModelController.h"
#import "Project.h"

@implementation DntImage

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
    DntImage *theEntity = [self findWithId:identifier];

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
    self.identifier = [NSString stringWithFormat:@"%@", json[@"_id"]];
    NSArray *images = json[@"img"];
    NSDictionary *firstImage = [images firstObject];
    NSString *imageUrl = firstImage[@"url"];
    self.url = imageUrl;
}

- (NSURL *)URL
{
    return [NSURL URLWithString:self.url];
}

@end
