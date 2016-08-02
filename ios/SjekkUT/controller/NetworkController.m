//
//  NetworkController.m
//  SjekkUt
//
//  Created by Henrik Hartz on 06/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "Backend.h"
#import "Challenge+Extension.h"
#import "Checkin+Extension.h"
#import "Defines.h"
#import "Location.h"
#import "ModelController.h"
#import "NetworkController.h"

#import <SSKeychain/SSKeychain.h>

#define SET_ETAG YES

@implementation NetworkController

#pragma mark api

+ (NetworkController *)instance
{
    static NetworkController *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseUrl = [NSURL URLWithString:@"https://api.nasjonalturbase.no"];
        NSString *debugUrl = [[NSProcessInfo processInfo] environment][@"OPPTUR_API_URL"];
        if (debugUrl)
        {
            baseUrl = [NSURL URLWithString:debugUrl];
            NSLog(@"overrode API url with %@", baseUrl);
        }

        _instance = [[NetworkController alloc] initWithBaseURL:baseUrl];
        _instance.responseSerializer = [AFJSONResponseSerializer serializer];
        _instance.requestSerializer = [AFJSONRequestSerializer serializer];
        [_instance.requestSerializer setValue:@"application/json"
                           forHTTPHeaderField:@"Content-Type"];
        [_instance.requestSerializer setValue:[backend uniqueIdentifier]
                           forHTTPHeaderField:@"device-id"];
        [_instance.requestSerializer setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTokenHeader) name:kSjekkUtNotificationLogin object:nil];

        _instance.failHandler = ^(NSURLSessionDataTask *tsk, NSError *err) {

            // if Etag returns unchanged, ignore - no update required
            if ([(NSHTTPURLResponse *)tsk.response statusCode] == 304)
            {
                NSLog(@"No change to %@ with Etag %@", tsk.originalRequest.URL, tsk.originalRequest.allHTTPHeaderFields[@"If-None-Match"]);
                return;
            }

            NSData *errorData = err.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];

            NSString *title = nil;
            NSString *details = @"";

            NSDictionary *serializedData = nil;

            if (errorData)
            {
                serializedData = [NSJSONSerialization JSONObjectWithData:errorData
                                                                 options:kNilOptions
                                                                   error:nil];
            }

            if (serializedData[@"details"])
            {
                title = NSLocalizedString(@"Info", @"info box title in network error");
                details = serializedData[@"details"];
                [backend showInfo:title message:details];
            }
            else
            {
                title = err.localizedDescription;
                NSURL *failingUrl = err.userInfo[NSURLErrorFailingURLErrorKey];
                if (failingUrl)
                {
                    NSString *lineBreak = details.length ? @"\n\n" : @"";
                    details = [details stringByAppendingFormat:@"%@%@", lineBreak, failingUrl.path];
                }
                [backend showError:title message:details];
            }
        };
    });
    return _instance;
}

- (void)clearETags
{
    NSArray *etags = @[ SjekkUtEtagChallenges, SjekkUtEtagCheckins, SjekkUtEtagMountains, SjekkUtEtagStatistics ];
    [etags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:obj];
    }];
}

- (NSURLSessionDataTask *)updateSummits
{
    NSString *etag = [[NSUserDefaults standardUserDefaults] valueForKey:SjekkUtEtagMountains];
    if (SET_ETAG)
    {
        [self.requestSerializer setValue:etag forHTTPHeaderField:@"If-None-Match"];
    }

    id task = [self GET:@"mountains/" parameters:nil success:^(NSURLSessionDataTask *tsk, id responseObject) {
        NSString *etag = [[(NSHTTPURLResponse *)tsk.response allHeaderFields] valueForKey:@"Etag"];
        [[NSUserDefaults standardUserDefaults] setValue:etag forKey:SjekkUtEtagMountains];

        // ensure summits that are deleted from API are hidden
        // TODO: use sets instead to limit core data updates
        for (Summit *summit in [Summit allSummits])
        {
            summit.hidden = @YES;
        }

        for (NSDictionary *json in responseObject)
        {
            Summit *summit = nil;
            summit = [Summit insertOrUpdate:json];
        }

        [model save];
        [self updateCheckins];
        [self updateChallenges];
    }
        failure:^(NSURLSessionDataTask *tsk, NSError *err) {
            // if Etag returns unchanged, ignore - no update required but we still want to
            // update checkins
            if ([(NSHTTPURLResponse *)tsk.response statusCode] == 304)
            {
                [self updateCheckins];
            }
            _failHandler(tsk, err);
        }];
    return task;
}

- (NSURLSessionDataTask *)updateCheckins
{
    NSString *etag = [[NSUserDefaults standardUserDefaults] valueForKey:SjekkUtEtagCheckins];
    if (SET_ETAG)
    {
        [self.requestSerializer setValue:etag forHTTPHeaderField:@"If-None-Match"];
    }

    id task = [self GET:@"checkins/" parameters:nil success:^(NSURLSessionDataTask *tsk, id responseObject) {
        NSString *etag = [[(NSHTTPURLResponse *)tsk.response allHeaderFields] valueForKey:@"Etag"];
        [[NSUserDefaults standardUserDefaults] setValue:etag forKey:SjekkUtEtagCheckins];

        for (NSDictionary *json in responseObject)
        {
            [Checkin insertOrUpdate:json];
        }
        [model save];
    }
                failure:_failHandler];
    return task;
}

- (NSURLSessionDataTask *)updateStatisticsFor:(Summit *)summit
{
    NSString *etag = [[NSUserDefaults standardUserDefaults] valueForKey:SjekkUtEtagStatistics];
    if (SET_ETAG)
    {
        [self.requestSerializer setValue:etag forHTTPHeaderField:@"If-None-Match"];
    }

    __weak Summit *weakSummit = summit;
    __weak typeof(self) weakSelf = self;

    id task = [self GET:[NSString stringWithFormat:@"mountains/%@/stats", summit.identifier] parameters:nil success:^(NSURLSessionDataTask *tsk, id responseObject) {
        NSString *etag = [[(NSHTTPURLResponse *)tsk.response allHeaderFields] valueForKey:@"Etag"];
        [[NSUserDefaults standardUserDefaults] setValue:etag forKey:SjekkUtEtagStatistics];
        if (weakSelf)
        {
            [weakSummit updateStatistics:responseObject];
            [model save];
        }
    }
                failure:_failHandler];
    return task;
}

- (NSURLSessionDataTask *)updateChallenges
{
    NSString *etag = [[NSUserDefaults standardUserDefaults] valueForKey:SjekkUtEtagChallenges];
    if (SET_ETAG)
    {
        [self.requestSerializer setValue:etag forHTTPHeaderField:@"If-None-Match"];
    }

    NSString *endpoint = @"challenges/";
    id task = [self GET:endpoint parameters:nil success:^(NSURLSessionDataTask *tsk, id responseObject) {
        NSString *etag = [[(NSHTTPURLResponse *)tsk.response allHeaderFields] valueForKey:@"Etag"];
        [[NSUserDefaults standardUserDefaults] setValue:etag forKey:SjekkUtEtagChallenges];

        [responseObject enumerateObjectsUsingBlock:^(NSDictionary *json, NSUInteger idx, BOOL *stop) {
            Challenge *challenge = nil;
            challenge = [Challenge insertOrUpdate:json];
        }];

        [model save];
    }
                failure:_failHandler];
    return task;
}

- (void)updateTokenHeader
{
    NSString *aToken = [SSKeychain passwordForService:SjekkUtKeychainServiceName
                                              account:kSjekkUtDefaultsToken];

    [self.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", aToken]
                  forHTTPHeaderField:@"Authorization"];
}

- (NSURLSessionDataTask *)checkinTo:(Summit *)summit and:(void (^)(Checkin *))performCallback
                                 or:(void (^)(NSURLSessionDataTask *, NSError *))fail
{
#ifdef TESTING
    [summit addCheckinsObject:[Checkin mock]];
    return nil;
#else
    NSString *endpoint = [NSString stringWithFormat:@"mountains/%@/checkin", summit.identifier];
    NSDictionary *params = @{
        @"location" : @{
            @"Lat" : @(locationBackend.currentLocation.coordinate.latitude),
            @"Lng" : @(locationBackend.currentLocation.coordinate.longitude)
        }
    };

    id task = [self POST:endpoint parameters:params
                 success:^(NSURLSessionDataTask *tsk, id responseObject) {

                     NSMutableDictionary *json = [responseObject mutableCopy];

                     Checkin *checkin = [Checkin insertOrUpdate:json];
                     summit.checkinCount = @([summit.checkinCount integerValue] + 1);
                     [summit updateStatistics:json[@"statistics"]];
                     [model save];

                     [[NSNotificationCenter defaultCenter] postNotificationName:SjekkUtCheckedInNotification
                                                                         object:checkin];

                     if (performCallback)
                     {
                         performCallback(checkin);
                     }
                 }
                 failure:fail];

    return task;
#endif
}

- (NSURLSessionDataTask *)joinChallenge:(Challenge *)challenge
{
    NSDictionary *parameters = @{};
    NSString *endpoint = [NSString stringWithFormat:@"challenges/%@/join", challenge.identifier];
    __weak typeof(self) weakSelf = self;

    id task = [self POST:endpoint parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        [Challenge insertOrUpdate:responseObject];
        [model save];
    }
        failure:^(NSURLSessionDataTask *task, NSError *error){
            //            if ([(NSHTTPURLResponse *)task.response statusCode] == 403)
            //            {
            //                [backend registerUserAnd:^{
            //                    [weakSelf joinChallenge:challenge];
            //                }];
            //            }
            //            else
            //            {
            //                network.failHandler(task, error);
            //            }
        }];
    return task;
}

- (void)registerUserName:(NSString *)user email:(NSString *)email withCallback:(void (^)())pFunction
{
    NSDictionary *parameters = @{ @"name" : user,
                                  @"email" : email };
    NSString *endpoint = @"users/";

    [self POST:endpoint parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        pFunction();
    }
        failure:^(NSURLSessionDataTask *task, NSError *error) {
            switch ([(NSHTTPURLResponse *)task.response statusCode])
            {
                case 403:
                    [backend showError:NSLocalizedString(@"Email or phone already registered", @"duplicate email phone title")
                               message:NSLocalizedString(@"That email or phone has already been registered", @"duplicate email phone message")];
                    break;
                case 404:
                    [backend showError:NSLocalizedString(@"Invalid email", @"malformed email title")
                               message:NSLocalizedString(@"Please provide a valid email", @"malformed email message")];
                    break;
                default:
                    [backend showError:NSLocalizedString(@"Failed registering email", @"failed registering email")
                               message:error.localizedDescription];
                    break;
            }
        }];
}
@end
