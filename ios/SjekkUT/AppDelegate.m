//
//  AppDelegate.m
//  Sjekk UT
//
//  Created by Henrik Hartz on 04/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <HockeySDK/HockeySDK.h>
#import <SSKeychain/SSKeychain.h>

#import "AppDelegate.h"
#import "Backend.h"
#import "Defines.h"
#import "ModelController.h"
#import "SjekkUtStyle.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"no.dnt.launched"] == false)
    {
        [SSKeychain deletePasswordForService:SjekkUtKeychainServiceName
                                     account:SjekkUtKeychainAccountName];

        [defaults setBool:YES forKey:@"no.dnt.launched"];
        [defaults synchronize];
    }

#ifndef DEBUG
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"7eb53486649f2d366b4907547549f35e"];
    // Configure the SDK in here only!
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation]; // This line is obsolete in the crash only build
#endif

    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;

    // apply appearance
    [SjekkUtStyle apply];

    // instantiate backend to get model notification
    [Backend instance];

    // instantiate database
    [ModelController instance];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [model save];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [model save];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [backend updateSummits];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [model save];
}

@end
