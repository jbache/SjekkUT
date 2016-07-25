//
//  Checkin.h
//  SjekkUt
//
//  Created by Henrik Hartz on 30/03/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "EntityScaffold.h"

@class Summit;

@interface Checkin : EntityScaffold

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *latitute;
@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) Summit *summit;

@end
