//
//  NSString+URL.m
//  SjekkUt
//
//  Created by Henrik Hartz on 20/05/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "NSString+URL.h"

@implementation NSString (URL)

- (NSURL*) URL
{
  return [NSURL URLWithString:self];
}

@end
