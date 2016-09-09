//
//  NSDateFormatter+instance.m
//  SjekkUt
//
//  Created by Henrik Hartz on 23/05/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "NSDateFormatter+instance.h"

@implementation NSDateFormatter (instance)

+ (NSDateFormatter*) instance
{
  static NSDateFormatter *formatterInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    formatterInstance = [[NSDateFormatter alloc] init];
  });
  return formatterInstance;
}

@end
