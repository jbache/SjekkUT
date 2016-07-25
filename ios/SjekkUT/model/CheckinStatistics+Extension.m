//
//  CheckinStatistics+Extension.m
//  SjekkUt
//
//  Created by Henrik Hartz on 30/03/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "Checkin+Extension.h"
#import "CheckinStatistics+Extension.h"
#import "ModelController.h"
#import "Summit+Extension.h"

@implementation CheckinStatistics (Extension)

+ (id)insertOrUpdate:(NSDictionary *)json
{
    NSFetchRequest *fetch = [[self class] fetch];
    NSString *identifier = json[@"id"];
    NSError *error = nil;
    CheckinStatistics *theCheckin = nil;

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
        theCheckin = [[self class] insert];
    }

    NSAssert(theCheckin != nil, @"Unable to aquire new or existing object");

    [theCheckin update:json];

    return theCheckin;
}

- (void)update:(NSDictionary *)json
{
    self.personalCount = json[@"personalCount"];
    self.dailyCount = json[@"dailyCount"];
    self.totalCount = json[@"totalCount"];
}

- (NSString *)verboseDescription
{

    NSString *lastCheckin = [NSString stringWithFormat:NSLocalizedString(@"You checked in to %@ %@.", @"last checkin time ago"), self.summit.name, self.summit.lastCheckin.timeAgo];

    if (self.summit.lastCheckin == nil)
    {
        lastCheckin = @"";
    }

    NSString *personalCheckins = @"";
    switch (self.personalCount.intValue)
    {
        case 0:
            personalCheckins = NSLocalizedString(@"You have never checked in here.", @"personal checkin description");
            lastCheckin = @"";
            break;
        case 1:
            personalCheckins = NSLocalizedString(@"You have checked in here once.", @"personal checkin description");
            break;
        default:
            personalCheckins = [NSString stringWithFormat:NSLocalizedString(@"You have checked in here %@ times.", @"personal checkin description"), self.personalCount];
            break;
    }

    NSString *dailyCheckins = @"";
    switch (self.dailyCount.intValue)
    {
        case 0:
            dailyCheckins = NSLocalizedString(@"Nobody have checked in here today.", @"daily checkin description");
            break;
        case 1:
            dailyCheckins = [NSString stringWithFormat:NSLocalizedString(@"Only one person have checked in here today.", @"daily checkin description"), self.dailyCount];
            break;
        default:
            dailyCheckins = [NSString stringWithFormat:NSLocalizedString(@"%@ people have checked in here today.", @"daily checkin description"), self.dailyCount];
            break;
    }

    NSString *totalCheckins = @"";
    switch (self.totalCount.intValue)
    {
        case 0:
            return NSLocalizedString(@"Nobody have checked in here.", @"total checkin description");
        case 1:
            return NSLocalizedString(@"In total, one person have checked in here.", @"single checkin description");
        default:
            totalCheckins = [NSString stringWithFormat:NSLocalizedString(@"In total, %@ people have checked in here.", @"total checkin description"), self.totalCount];
            break;
    }

    return [[NSString stringWithFormat:@"%@ %@ %@ %@", lastCheckin, personalCheckins, dailyCheckins, totalCheckins] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}
@end
