//
//  DntGroup.m
//  SjekkUt
//
//  Created by Henrik Hartz on 16/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

#import "DntGroup.h"
#import "ModelController.h"
#import "Project.h"

@implementation DntGroup

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

    DntGroup *theEntity = [self findWithId:identifier];

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
    setIfNotEqual(self.name, json[@"navn"]);
    setIfNotEqual(self.naming, json[@"navngiving"]);
}

@end
