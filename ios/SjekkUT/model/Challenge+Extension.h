//
//  Challenge+Extension.h
//  SjekkUt
//
//  Created by Henrik Hartz on 20/05/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Challenge.h"

@interface Challenge (Extension)

- (void)update:(NSDictionary *)json;
- (NSInteger)summitedCount;

+ (Challenge *)mock;
+ (id)insertOrUpdate:(NSDictionary *)json;

@end
