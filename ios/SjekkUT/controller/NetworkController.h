//
//  NetworkController.h
//  SjekkUt
//
//  Created by Henrik Hartz on 06/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#define network [NetworkController instance]

@class Summit;
@class Challenge;
@class Checkin;

@interface NetworkController : AFHTTPSessionManager

+ (NetworkController *)instance;

@property (nonatomic, copy) void (^failHandler)(NSURLSessionDataTask *task, NSError *error);

- (NSURLSessionDataTask *)checkinTo:(Summit *)summit
                                and:(void (^)(Checkin *checkin))performCallback
                                 or:(void (^)(NSURLSessionDataTask *task, NSError *err))fail;

- (NSURLSessionDataTask *)updateStatisticsFor:(Summit *)summit;
- (NSURLSessionDataTask *)updateChallenges;
- (NSURLSessionDataTask *)joinChallenge:(Challenge *)challenge;
- (void)registerUserName:(NSString *)user email:(NSString *)email withCallback:(void (^)())pFunction;
- (void)clearETags;
@end
