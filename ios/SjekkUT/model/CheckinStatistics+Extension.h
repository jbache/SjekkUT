//
//  CheckinStatistics+Extension.h
//  SjekkUt
//
//  Created by Henrik Hartz on 30/03/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "CheckinStatistics.h"

@interface CheckinStatistics (Extension)
- (NSString *)verboseDescription;
- (void)update:(NSDictionary *)json;
+ (id)insertOrUpdate:(NSDictionary *)json;

@end
