//
//  Backend.h
//  SjekkUt
//
//  Created by Henrik Hartz on 04/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "NSDateFormatter+instance.h"
#import "Summit+Extension.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIAlertView.h>

#define backend [Backend instance]

@class Challenge;

@interface Backend : NSObject <UIAlertViewDelegate>

+ (Backend *)instance;

@property (nonatomic, copy) void (^callback)(void);

- (Summit *)findNearest:(CLLocationCoordinate2D)coordinate;
- (void)showError:(NSString *)title message:(NSString *)message;
- (void)showInfo:(NSString *)title message:(NSString *)message;
- (NSArray *)summits;
- (NSString *)uniqueIdentifier;
- (NSURLSessionDataTask *)updateSummits;
- (NSURLSessionDataTask *)updateCheckins;
- (NSURLSessionDataTask *)joinChallenge:(Challenge *)challenge;

@end
