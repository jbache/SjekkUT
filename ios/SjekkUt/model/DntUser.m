//
//  DntUser.m
//  SjekkUt
//
//  Created by Henrik Hartz on 23/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

#import "Checkin.h"
#import "DntUser.h"
#import "ModelController.h"
#import "Project.h"

static DntUser *_currentUser = nil;

@implementation DntUser

+ (instancetype)currentUser
{
    return _currentUser;
}

+ (void)setCurrentUser:(DntUser *_Nullable)aUser
{
    _currentUser = aUser;
}

+ (instancetype)insertOrUpdate:(id)json
{
    NSString *identifier = nil;
    if ([json isKindOfClass:NSDictionary.class])
    {
        identifier = [json[@"sherpa_id"] stringValue];
    }
    else if ([json isKindOfClass:NSString.class])
    {
        identifier = json;
    }
    DntUser *theEntity = [self findWithId:identifier];

    if (theEntity == nil && identifier)
    {
        theEntity = [DntUser insert];
        theEntity.identifier = identifier;
    }

    NSAssert(theEntity != nil, @"Unable to aquire new or existing object");

    if ([json isKindOfClass:NSDictionary.class])
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
    setIfNotEqual(self.firstName, json[@"fornavn"]);
    setIfNotEqual(self.lastName, json[@"etternavn"]);
}

- (NSString *)fullName
{
    return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
}

@end
