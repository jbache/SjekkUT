//
//  DntImage.m
//  SjekkUt
//
//  Created by Henrik Hartz on 03/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

#import "DntImage.h"
#import "DntImageSize.h"
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
    self.sizes = [self parseImageSizes:json[@"img"]];
}

- (NSSet *)parseImageSizes:(NSArray *)sizesDict
{
    NSMutableSet *sizes = [NSMutableSet set];
    for (NSDictionary *sizeDict in sizesDict)
    {
        DntImageSize *size = [DntImageSize insertOrUpdate:sizeDict];
        [sizes addObject:size];
    }
    return sizes;
}

- (NSURL *)URLforSize:(CGSize)desiredSize
{
    NSArray *sortedSizes = [self.sizes sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"width" ascending:NO] ]];
    DntImageSize *theSize = [sortedSizes firstObject];
    for (DntImageSize *aSize in sortedSizes)
    {
        if (aSize.width.floatValue >= desiredSize.width && aSize.height.floatValue >= desiredSize.height)
        {
            theSize = aSize;
        }
        else
        {
            break;
        }
    }
    //NSAssert(theSize.width != nil && theSize.height != nil, @"no size");
    NSLog(@"image size %@ %@", theSize.width, theSize.height);
    return [NSURL URLWithString:theSize.url];
}

@end
