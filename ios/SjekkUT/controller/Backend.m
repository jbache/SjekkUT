//
//  Backend.m
//  SjekkUt
//
//  Created by Henrik Hartz on 04/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "Backend.h"
#import "Defines.h"
#import "Location.h"
#import "ModelController.h"
#import "NetworkController.h"

#import <SSKeychain/SSKeychain.h>

@interface NetworkController ()
- (NSURLSessionDataTask *)updateSummits;
- (NSURLSessionDataTask *)updateCheckins;
@end

@implementation Backend
{
    BOOL modelReady;
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;

    // stash a unique ID that will be reused for identification
    NSString *uuid = [SSKeychain passwordForService:SjekkUtKeychainServiceName
                                            account:SjekkUtKeychainAccountName];

    if (!uuid)
    {
        uuid = [[NSUUID UUID] UUIDString];
        [SSKeychain setPassword:uuid forService:SjekkUtKeychainServiceName
                        account:SjekkUtKeychainAccountName];
    }
    uuid = [self uniqueIdentifier];
    NSAssert(uuid.length > 0, @"no unique identifier!");

    [defaultNotifyer addObserver:self selector:@selector(handleModelReady:)
                            name:SjekkUtDatabaseModelReadyNotification
                          object:nil];

#ifdef OPPTURTEST
    for (int i = 0; i < 24; ++i)
    {
        [Summit mock];
    }
#endif
    return self;
}

+ (Backend *)instance
{
    static Backend *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[Backend alloc] init];
    });

    return _instance;
}

- (void)handleModelReady:(NSNotification *)notification
{
    modelReady = YES;
}

- (Summit *)findNearest:(CLLocationCoordinate2D)coordinate;
{
    Summit *summit = nil;

    NSArray *sorts = @[ [NSSortDescriptor sortDescriptorWithKey:@"distance"
                                                      ascending:NO] ];
    NSArray *summits = [self.summits sortedArrayUsingDescriptors:sorts];

    summit = [summits lastObject];
    return summit;
}

- (void)showError:(NSString *)title message:(NSString *)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)showInfo:(NSString *)title message:(NSString *)message
{
    [self showError:title message:message];
}

- (NSArray *)summits
{
    NSManagedObjectContext *context = model.managedObjectContext;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Summit"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];

    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    NSAssert(!error, @"failed fetch: %@", error);

    return fetchedObjects ?: @[];
}

- (NSString *)uniqueIdentifier
{
    NSString *debugIdentifier = [[NSProcessInfo processInfo] environment][@"OPPTUR_DEVICE_IDENTIFIER"];
    if (debugIdentifier)
    {
        return debugIdentifier;
    }

    static NSString *uuid = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uuid = [SSKeychain passwordForService:SjekkUtKeychainServiceName
                                      account:SjekkUtKeychainAccountName];
    });
    return uuid;
}

- (NSURLSessionDataTask *)updateSummits
{
    if (modelReady)
        return [network updateSummits];
    return nil;
}

- (NSURLSessionDataTask *)updateCheckins
{
    if (modelReady)
        return [network updateCheckins];
    return nil;
}

- (NSURLSessionDataTask *)joinChallenge:(Challenge *)challenge
{
    return [network joinChallenge:challenge];
}

- (void)registerUserAnd:(void (^)())pFunction
{
    if (pFunction)
    {
        _callback = pFunction;
    }
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Submit email", @"email title")
                                                        message:NSLocalizedString(@"To participate you need to provide a valid email so we can contact prize winners.", @"registration message")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", @"email cancel")
                                              otherButtonTitles:NSLocalizedString(@"OK", @"email ok"), nil];
    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    [alertView textFieldAtIndex:1].secureTextEntry = NO; //Will disable secure text entry for second textfield.
    [alertView textFieldAtIndex:0].placeholder = NSLocalizedString(@"Name", @"name input label");
    [alertView textFieldAtIndex:1].placeholder = NSLocalizedString(@"Email", @"email input label");
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        [network registerUserName:[alertView textFieldAtIndex:0].text
                            email:[alertView textFieldAtIndex:1].text
                     withCallback:^{
                         if (_callback)
                             _callback();
                         _callback = nil;
                     }];
    }
}

- (void)login:(NSString *)authorization
{
    // store token in keychain
    [SSKeychain setPassword:authorization
                 forService:SjekkUtKeychainServiceName
                    account:kSjekkUtDefaultsToken];

    [[NSNotificationCenter defaultCenter] postNotificationName:kSjekkUtNotificationLogin object:nil];
}

- (BOOL)isLoggedIn
{
    return [SSKeychain passwordForService:SjekkUtKeychainServiceName account:kSjekkUtDefaultsToken].length > 0;
}

- (void)logout
{
    [SSKeychain deletePasswordForService:SjekkUtKeychainServiceName account:kSjekkUtDefaultsToken];
}

@end
