//
//  Summits.m
//  SjekkUt
//
//  Created by Henrik Hartz on 04/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "Backend.h"
#import "ChallengeCell.h"
#import "Checkin+Extension.h"
#import "Defines.h"
#import "Location.h"
#import "ModelController.h"
#import "RulesView.h"
#import "SummitCell.h"
#import "SummitView.h"
#import "Summits.h"

#import <HockeySDK/HockeySDK.h>

@interface Summits ()

@property (retain, nonatomic) NSFetchedResultsController *results;

@end

@implementation Summits
{

    BITFeedbackManager *feedbackManager;
    NSMutableArray *headers;
}
@synthesize results;

#pragma mark view

- (void)viewDidLoad
{
    //    [self.infoButton setTitle:[NSString fontAwesomeIconStringForEnum:FAIconInfoSign]
    //                     forState:UIControlStateNormal];
    self.checkinButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.checkinButton.titleLabel.numberOfLines = 2;
    self.checkinButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.checkedInNotificationView.alpha = 0;
    self.results = nil;

    headers = [@[] mutableCopy];

    [defaultNotifyer addObserver:self selector:@selector(didCheckInTo:)
                            name:SjekkUtCheckedInNotification
                          object:nil];
    [defaultNotifyer addObserver:self selector:@selector(handleModelReady:)
                            name:SjekkUtDatabaseModelReadyNotification
                          object:nil];
    [locationBackend addObserver:self forKeyPath:@"currentLocation"
                         options:NSKeyValueObservingOptionInitial
                         context:nil];

    feedbackManager = [[BITFeedbackManager alloc] init];
    //    [self.feedbackButton setTitle:[NSString fontAwesomeIconStringForEnum:FAIconComments]
    //                         forState:UIControlStateNormal];
    [super viewDidLoad];
}

- (void)dealloc
{
    [locationBackend removeObserver:self forKeyPath:@"currentLocation"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self updateData];

    [super viewDidAppear:animated];
}

- (void)updateData
{
    [backend updateSummits];
    [locationBackend getSingleUpdate:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"currentLocation"] && locationBackend.currentLocation)
    {
        [self updateCheckinButton];
        [self updateDistance];
    }
}

- (void)updateDistance
{
    for (Summit *summit in results.fetchedObjects)
    {
        [summit updateDistance];
    }
    [model save];
    [self.tableView reloadData];
}

- (void)updateCheckinButton
{
    [UIView animateWithDuration:0.25f animations:^{
        //      self.checkinButton.enabled = locationBackend.currentLocation !=nil;
        //      self.checkinButton.alpha = self.checkinButton.enabled ? 1.0f : 0.3f;
    }];
}

- (IBAction)clickedFeedback:(id)sender
{
    [feedbackManager showFeedbackListView];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showSummit"] && [sender isKindOfClass:[Summit class]])
    {
        SummitView *summitView = segue.destinationViewController;
        summitView.summit = sender;
    }
}

#pragma mark table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [results sections].count;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    NSUInteger count = 0;
    if ([[results sections] count] > 0)
    {
        id<NSFetchedResultsSectionInfo> sectionInfo = [results sections][section];
        count = [sectionInfo numberOfObjects];
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SummitCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SummitCell"];
    Summit *summit = [results objectAtIndexPath:indexPath];
    cell.summit = summit;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = @"";
    if ([[results sections] count] > 0)
    {
        id<NSFetchedResultsSectionInfo> sectionInfo = [results sections][section];
        title = NSLocalizedString([sectionInfo name], @"name of section header");
    }
    else
    {
        title = @"";
    }
    NSLog(@"%@", title);
    return title;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:section];
    Summit *summit = [results objectAtIndexPath:path];
    Challenge *challenge = summit.challenge;
    id cell = nil;
    if (![challenge.identifier isEqualToString:@"empty-challenge"])
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ChallengeHeader"];
        [(ChallengeCell *)cell setChallenge:challenge];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NoChallengeHeader"];
    }
    // prevent getting constraints we didn't ask for in the header cell, should
    // be covered by auto layout constrains
    UIView *view = [(UITableViewCell *)cell contentView];
    [view setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    // need to store the cell to prevent deallocation since it's not really using correct dequeue
    [headers addObject:cell];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    Summit *summit = [results objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    Challenge *challenge = summit.challenge;
    if (challenge.identifier.length)
    {
        return 120.0f;
    }
    return 44.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    Summit *summit = [results objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"showSummit" sender:summit];
}

#pragma mark fetched results controller

- (void)handleModelReady:(NSNotification *)notification
{
    ModelController *modelController = notification.object;
    [self setupResults:modelController.managedObjectContext];
    [self updateData];
}

- (void)setupResults:(NSManagedObjectContext *)objectContext
{
    NSLog(@"objectContext: %@", objectContext);
    NSAssert([objectContext isKindOfClass:[NSManagedObjectContext class]], @"not an object context");
    if (!self.results)
    {
        NSFetchRequest *fetch = [Summit fetch];
        fetch.sortDescriptors = @[
            [[NSSortDescriptor alloc] initWithKey:@"challenge.identifier" ascending:NO],
            [[NSSortDescriptor alloc] initWithKey:@"distance" ascending:YES]
        ];
        fetch.predicate = [NSPredicate predicateWithFormat:@"hidden = NO"];

        self.results = [[NSFetchedResultsController alloc] initWithFetchRequest:fetch
                                                           managedObjectContext:objectContext
                                                             sectionNameKeyPath:@"challenge.identifier"
                                                                      cacheName:nil];
        self.results.delegate = self;
        NSError *error;
        if (![results performFetch:&error])
        {
            NSLog(@"Failed fetching: %@", error);
        }
        NSLog(@"results: %@, sections: %ld", self.results, (long)[self.results sections].count);
        [self.tableView reloadData];
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type)
    {
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

#pragma mark notification toast

- (void)animateNotification
{
    __weak typeof(self) weakSelf = self;
    [self animateCheckinNotification:1];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf animateCheckinNotification:0];
    });
}

- (void)animateCheckinNotification:(CGFloat)alpha;
{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.checkedInNotificationView.alpha = alpha;
    }];
}

- (void)didCheckInTo:(NSNotification *)notification
{
    Checkin *checkin = notification.object;
    Summit *summit = checkin.summit;
    NSString *text = [NSString stringWithFormat:NSLocalizedString(@"Yay! Checked in to %@", @"check in notification text"), summit.name];
    self.checkedInNotificationLabel.text = text;
    [self animateNotification];
}

@end
