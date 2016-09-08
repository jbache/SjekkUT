//
//  defines.h
//  Sjekk UT
//
//  Created by Henrik Hartz on 10/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

@import Foundation;

#ifndef SjekkUt_defines_h
#define SjekkUt_defines_h

static NSString *__nonnull kSjekkUtDefaultsToken = @"com.dnt.sjekkut.defaults.token";
static NSString *__nonnull kSjekkUtDefaultsTokenExpiry = @"com.dnt.sjekkut.defaults.tokenexpiry";
static NSString *__nonnull kSjekkUtDefaultsRefreshToken = @"com.dnt.sjekkut.defaults.refreshtoken";
static NSString *__nonnull kSjekkUtDefaultsUserId = @"com.dnt.sjekkut.defaults.user.id";
static NSString *__nonnull kSjekkUtNotificationLoggedOut = @"com.dnt.sjekkut.notification.loggedout";
static NSString *__nonnull kSjekkUtNotificationAuthorized = @"com.dnt.sjekkut.notification.authorized";
static NSString *__nonnull kSjekkUtNotificationLoggedIn = @"com.dnt.sjekkut.notification.loggedin";
static NSString *__nonnull kSjekkUtNotificationCheckinChanged = @"com.dnt.sjekkut.notification.checkinchanged";
static NSString *__nonnull kSjekkUtNotificationLocationChanged = @"com.dnt.sjekkut.notification.locationchanged";

static NSTimeInterval kSjekkUtConstantAnimationDuration = 0.250;

static NSString *__nonnull kSjekkUtConstantTemporaryManagedObjectIdHeaderKey = @"X-SjekkUt-Temporary-Object-Id";
#define defaultNotifyer [NSNotificationCenter defaultCenter]

#define SjekkUtCheckedInNotification @"com.dnt.opptur.CheckedIn"
#define SjekkUtTimeoutNotification @"com.dnt.opptur.Timeout"
#define SjekkUtDatabaseModelReadyNotification @"com.dnt.opptur.DatabaseModelReady"

#define SjekkUtDefaultUUID @"com.dnt.opptur.UUID"
#define SjekkUtKeychainServiceName @"DntSjekkUt"
#define SjekkUtKeychainAccountName @"UniqueId"

#define SjekkUtShowOwnLocationOnMap @"com.dnt.opptur.ShowOwnLocation"

#define SjekkUtEtagMountains @"com.dnt.opptur.etag.Mountains"
#define SjekkUtEtagCheckins @"com.dnt.opptur.etag.Checkins"
#define SjekkUtEtagStatistics @"com.dnt.opptur.etag.Statistics"
#define SjekkUtEtagChallenges @"com.dnt.opptur.etag.Challenges"

#define SjekkUtLocationTimeout 30
#define SjekkUtCheckinTimeLimit 60 * 60 * 24
#define SjekkUtCheckinDistanceLimit 200

#define SjekkUtMapZoomLevel 14.0f

#define UIColorFromRGB(rgbValue)                                         \
    [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0 \
                    green:((float)((rgbValue & 0x00FF00) >> 8)) / 255.0  \
                     blue:((float)((rgbValue & 0x0000FF) >> 0)) / 255.0  \
                    alpha:1.0]

#define dntLightGray UIColorFromRGB(0xbcbdbf)
#define dntLightGray30 [dntLightGray colorWithAlphaComponent:.3f]
#define dntDarkGray UIColorFromRGB(0x4c4d4f)
#define dntRed UIColorFromRGB(0xd82d20)
#define dntBlue UIColorFromRGB(0x0072b4)

#endif
