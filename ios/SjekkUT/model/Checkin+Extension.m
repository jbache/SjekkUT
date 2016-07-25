//
//  Checkin+Extension.m
//  SjekkUt
//
//  Created by Henrik Hartz on 09/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <UIKit/UIDevice.h>

#import "Checkin+Extension.h"
#import "CheckinStatistics+Extension.h"
#import "ModelController.h"
#import "NSDate+DateTools.h"
#import "Summit+Extension.h"

@implementation Checkin (Extension)

#pragma mark initialization

+ (Checkin *)mock
{
    Checkin *_mock = [[Checkin alloc] initWithEntity:self.entity
                      insertIntoManagedObjectContext:model.managedObjectContext];

    _mock.identifier = [NSString stringWithFormat:@"%@", @(random())];
    _mock.name = @"mock checkin";
    _mock.date = [NSDate date];

    return _mock;
}

+ (Checkin *)insertOrUpdate:(NSDictionary *)json
{
    NSFetchRequest *fetch = [[self class] fetch];
    NSString *identifier = json[@"id"];
    NSError *error = nil;
    Checkin *theCheckin = nil;

    fetch.predicate = [NSPredicate predicateWithFormat:@"identifier = %@", identifier];
    NSArray *results = [model.managedObjectContext executeFetchRequest:fetch
                                                                 error:&error];
    theCheckin = [results lastObject];

    if (error)
    {
        NSLog(@"failed looking up Checkin with id %@", json[@"id"]);
    }
    else if (!theCheckin)
    {
        theCheckin = [Checkin insert];
    }

    NSAssert(theCheckin != nil, @"Unable to aquire new or existing object");

    [theCheckin update:json];

    return theCheckin;
}

- (void)update:(NSDictionary *)json
{
    if (json.count != 6)
        NSLog(@"!!! unhandled JSON keys !!!");
    NSDateFormatter *dateFormatter = [self dateFormatter];

    self.identifier = json[@"id"];
    self.date = [dateFormatter dateFromString:json[@"timestamp"]];
    NSString *mountainId = [NSString stringWithFormat:@"%@", json[@"mountainId"]];
    if (!self.summit && mountainId.length > 0)
    {
        self.summit = [Summit findWithId:mountainId];
    }
    self.latitute = json[@"location"][@"Lat"];
    self.longitude = json[@"location"][@"Lng"];
}

#pragma mark util

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

- (NSString *)timeAgo
{
    return self.date.timeAgoSinceNow;
}

@end
