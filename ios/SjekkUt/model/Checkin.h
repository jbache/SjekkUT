//
//  Checkin.h
//  SjekkUt
//
//  Created by Henrik Hartz on 03/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "DntUser.h"
#import "EntityScaffold.h"

@class Place;

NS_ASSUME_NONNULL_BEGIN

@interface Checkin : EntityScaffold

+ (Checkin *)insertOrUpdate:(NSDictionary *)json;
+ (NSDateFormatter *)dateFormatter;
+ (NSArray *)visitsLast30Days;
- (void)update:(NSDictionary *)json;
- (NSString *)timeAgo;

@end

NS_ASSUME_NONNULL_END

#import "Checkin+CoreDataProperties.h"
