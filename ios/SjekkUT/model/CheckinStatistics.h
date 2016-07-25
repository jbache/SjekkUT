//
//  CheckinStatistics.h
//  SjekkUt
//
//  Created by Henrik Hartz on 30/03/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "EntityScaffold.h"

@class Checkin, Summit;

@interface CheckinStatistics : EntityScaffold

@property (nonatomic, retain) NSNumber *dailyCount;
@property (nonatomic, retain) NSNumber *personalCount;
@property (nonatomic, retain) NSNumber *totalCount;
@property (nonatomic, retain) Checkin *checkin;
@property (nonatomic, retain) Summit *summit;

@end
