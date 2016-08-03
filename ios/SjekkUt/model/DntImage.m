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
    NSArray *images = json[@"img"];
    NSDictionary *firstImage = [images firstObject];
    NSString *imageUrl = firstImage[@"url"];
    self.url = imageUrl;
}

@end
