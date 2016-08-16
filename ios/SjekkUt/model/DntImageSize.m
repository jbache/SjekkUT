//
//  DntImageSize.m
//  SjekkUt
//
//  Created by Henrik Hartz on 15/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

#import "DntImage.h"
#import "DntImageSize.h"
#import "ModelController.h"

@implementation DntImageSize

+ (instancetype)insertOrUpdate:(id)json
{
    NSString *identifier = nil;
    if ([json isKindOfClass:[NSDictionary class]])
    {
        identifier = json[@"etag"];
    }
    else if ([json isKindOfClass:[NSString class]])
    {
        identifier = json;
    }
    DntImageSize *theEntity = [self findWithId:identifier];

    if (!theEntity && identifier != nil)
    {
        theEntity = [self insert];
        theEntity.etag = identifier;
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
    fetch.predicate = [NSPredicate predicateWithFormat:@"etag = %@", identifier];
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
    setIfNotEqual(self.width, json[@"width"]);
    setIfNotEqual(self.height, json[@"height"]);
    setIfNotEqual(self.url, json[@"url"]);
}

@end
