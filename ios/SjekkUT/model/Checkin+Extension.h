//
//  Checkin+Extension.h
//  SjekkUt
//
//  Created by Henrik Hartz on 09/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "Checkin.h"

@interface Checkin (Extension)

@property (readonly) NSString *timeAgo;

+ (Checkin *)mock;
+ (Checkin *)insertOrUpdate:(NSDictionary *)json;

@end
