//
//  Challenge+Extension.m
//  SjekkUt
//
//  Created by Henrik Hartz on 20/05/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "Challenge+Extension.h"
#import "Checkin+Extension.h"
#import "ModelController.h"
#import "NSDateFormatter+instance.h"
#import "Summit+Extension.h"

@implementation Challenge (Extension)

+ (Challenge *)mock
{
    Challenge *mock = [self insertOrUpdate:@{
        @"id" : @"12345",
        @"title" : @"test challenge",
        @"url" : @"http://turistforeningen.no",
        @"logoUrl" : @"",
        @"footerUrl" : @"",
        @"validFrom" : [[NSDateFormatter instance] stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]],
        @"validTo" : [[NSDateFormatter instance] stringFromDate:[NSDate dateWithTimeIntervalSinceNow:DBL_MAX]],
        @"joined" : @NO,
        @"mountains" : @[]
    }];
    return mock;
}

+ (id)insertOrUpdate:(NSDictionary *)json
{
    NSFetchRequest *fetch = [[self class] fetch];
    NSString *identifier = json[@"id"];
    NSError *error = nil;
    Challenge *theChallenge = nil;

    fetch.predicate = [NSPredicate predicateWithFormat:@"identifier = %@", identifier];
    NSArray *results = [model.managedObjectContext executeFetchRequest:fetch
                                                                 error:&error];
    theChallenge = [results lastObject];

    if (error)
    {
        NSLog(@"failed looking up Challenge with id %@", json[@"id"]);
    }
    else if (!theChallenge)
    {
        theChallenge = [Challenge insert];
    }

    NSAssert(theChallenge != nil, @"Unable to aquire new or existing object");

    [theChallenge update:json];

    return theChallenge;
}

- (void)update:(NSDictionary *)json
{
    if (json.count != 9)
        NSLog(@"!!! unhandled JSON keys !!!!");

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    self.identifier = [NSString stringWithFormat:@"%@", json[@"id"]];
    self.name = json[@"title"];
    self.infoUrl = json[@"url"];
    self.logoUrl = json[@"logoUrl"];
    self.footerUrl = json[@"footerUrl"];
    self.validFrom = [dateFormatter dateFromString:json[@"validFrom"]];
    self.validTo = [dateFormatter dateFromString:json[@"validTo"]];
    self.participating = json[@"joined"];
    self.userProgress = json[@"userProgress"];

    // update the summits which are part of the challenge
    NSArray *mountainIds = json[@"mountains"];

    if (mountainIds != nil && ![mountainIds isKindOfClass:[NSNull class]])
    {
        // potentially convert the mountain id's to string ids
        NSMutableArray *mountainIdStrings = [@[] mutableCopy];
        [mountainIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [mountainIdStrings addObject:[NSString stringWithFormat:@"%@", obj]];
        }];

        NSArray *mountains = [Summit entitiesWithPredicate:[NSPredicate predicateWithFormat:@"identifier IN %@", mountainIdStrings]];
        NSSet *summitsInChallenge = [NSSet setWithArray:mountains];
        if (![summitsInChallenge isEqualToSet:self.summits])
        {
            self.summits = summitsInChallenge;
        }
    }
    NSAssert(self.identifier && self.identifier.length, @"No identifier set");
}

- (NSInteger)summitedCount
{
    NSNumber *userProgress = self.userProgress;
    if (userProgress != nil)
    {
        return [userProgress integerValue];
    }

    NSDate *from = self.validFrom;
    NSDate *to = self.validTo;
    if (!from)
        from = [NSDate dateWithTimeIntervalSince1970:0];
    if (!to)
        to = [NSDate dateWithTimeIntervalSinceNow:DBL_MAX];

    NSMutableArray *mountainIds = [@[] mutableCopy];
    [self.summits enumerateObjectsUsingBlock:^(Summit *obj, BOOL *stop) {
        [mountainIds addObject:obj.identifier];
    }];

    NSPredicate *checkinsPredicate = [NSPredicate predicateWithFormat:@"summit.identifier IN %@ AND date > %@ AND date < %@", mountainIds, from, to];
    NSArray *checkins = [Checkin entitiesWithPredicate:checkinsPredicate];
    return checkins.count;
}

@end
