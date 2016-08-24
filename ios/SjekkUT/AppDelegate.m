//
//  AppDelegate.m
//  Sjekk UT
//
//  Created by Henrik Hartz on 04/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <HockeySDK/HockeySDK.h>
#import <SSKeychain/SSKeychain.h>

#import "AppDelegate.h"
#import "Defines.h"
#import "ModelController.h"
#import "SjekkUT-Swift.h"
#import "SjekkUtStyle.h"

// thanks to http://stackoverflow.com/a/36926620
#ifdef DEBUG

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@implementation UIView (FixViewDebugging)

+ (void)load
{
    Method original = class_getInstanceMethod(self, @selector(viewForBaselineLayout));
    class_addMethod(self, @selector(viewForFirstBaselineLayout), method_getImplementation(original), method_getTypeEncoding(original));
    class_addMethod(self, @selector(viewForLastBaselineLayout), method_getImplementation(original), method_getTypeEncoding(original));
}

@end

#endif

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

    //#ifndef DEBUG
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:[@"com.hockeyapp-ios.appid" loadFileContentsInClass:self.class]];
    // Configure the SDK in here only!
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation]; // This line is obsolete in the crash only build
                                                                                     //#endif

    [SwiftHelper initNetworkIndicator];

    // apply appearance
    [SjekkUtStyle apply];

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
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [model save];
}

@end
