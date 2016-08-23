//
//  Checkin.m
//  SjekkUt
//
//  Created by Henrik Hartz on 03/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

#import "Checkin.h"
#import "DntUser.h"
#import "NSDate+DateTools.h"
#import "Place.h"
#import "Project.h"
#import "SjekkUT-Swift.h"

#import "ModelController.h"

@implementation Checkin

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
        theCheckin.identifier = identifier;
    }

    NSAssert(theCheckin != nil, @"Unable to aquire new or existing object");

    [theCheckin update:json];

    return theCheckin;
}

- (void)update:(NSDictionary *)json
{
    NSDateFormatter *dateFormatter = [self dateFormatter];
    setIfNotEqual(self.date, [dateFormatter dateFromString:json[@"timestamp"]]);
    NSString *mountainId = [NSString stringWithFormat:@"%@", json[@"ntb_steder_id"]];
    if (self.place == nil && mountainId.length > 0)
    {
        self.place = [Place findWithId:mountainId];
    }
    NSArray *coordinates = json[@"location"][@"coordinates"];
    setIfNotEqual(self.latitute, [coordinates objectAtIndex:1]);
    setIfNotEqual(self.longitude, [coordinates objectAtIndex:0]);
    DntUser *aUser = [DntUser findWithId:json[@"dnt_user_id"]];
    if (aUser != nil)
    {
        setIfNotEqual(self.user, aUser);
    }

    for (Project *project in self.place.projects)
    {
        [project updateHasCheckin];
    }
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
    if (self.date != nil)
    {
        return self.date.timeAgo;
    }
    return @"";
}

@end
