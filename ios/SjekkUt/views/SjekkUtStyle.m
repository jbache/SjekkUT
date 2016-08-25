//
//  SjekkUtStyle.m
//  SjekkUt
//
//  Created by Henrik Hartz on 11/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "Defines.h"
#import "DntNavigationBar.h"
#import "DntRedView.h"
#import "SjekkUtStyle.h"

#import <UIKit/UIKit.h>

@implementation SjekkUtStyle

+ (void)apply
{
    [[DntNavigationBar appearance] setBarTintColor:dntRed];
    [[DntNavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UIProgressView appearance] setTintColor:dntBlue];
    [[UILabel appearanceWhenContainedIn:[UINavigationBar class], nil] setTextColor:[UIColor whiteColor]];
    [[DntRedView appearance] setBackgroundColor:dntRed];
}

@end
