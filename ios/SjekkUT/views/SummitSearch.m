//
//  SummitSearch.m
//  SjekkUt
//
//  Created by Henrik Hartz on 05/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "Backend.h"
#import "Checkin.h"
#import "Defines.h"
#import "Location.h"
#import "ModelController.h"
#import "NSUrlRequest+cURL.h"
#import "NetworkController.h"
#import "Summit+Extension.h"
#import "SummitSearch.h"
#import "SummitView.h"

@implementation SummitSearch

#pragma mark view

- (id)init
{
    self = [super init];

    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // ensure we post a timeout notification if the view is still alive after a
    // certain time
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SjekkUtLocationTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakSelf)
        {
            [weakSelf.navigationController popViewControllerAnimated:YES];
            [defaultNotifyer postNotificationName:SjekkUtTimeoutNotification object:nil];
        }
    });

    [self.activityIndicator startAnimating];
    [locationBackend getSingleUpdate:^(CLLocation *loc) {

        [weakSelf.activityIndicator stopAnimating];

        Summit *summit = [backend findNearest:loc.coordinate];
        [weakSelf.checkinLabel setText:NSLocalizedString(@"Checking in...", @"Checking in label in summit search")];

        void (^finally)(id) = ^(id sender) {
            [weakSelf performSegueWithIdentifier:@"showSummit" sender:sender];
        };

        void (^successHandler)(Checkin *) = ^(Checkin *checkin) {
            finally(checkin);
        };

        void (^failHandler)() = ^(NSURLSessionDataTask *task, NSError *err) {
            network.failHandler(task, err);
            finally(summit);
        };

        [network checkinTo:summit and:successHandler
                        or:failHandler];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showSummit"])
    {
        SummitView *summitView = segue.destinationViewController;
        if ([sender isKindOfClass:[Summit class]])
        {
            summitView.summit = sender;
        }
        if ([sender isKindOfClass:[Checkin class]])
        {
            summitView.checkin = sender;
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    // remove the search view from the navigation stack, little sense in pop'ing
    // back to this view from SummitView
    id viewControllers = [self.navigationController.viewControllers mutableCopy];
    [viewControllers removeObject:self];
    self.navigationController.viewControllers = viewControllers;

    [super viewDidDisappear:animated];
}

@end
