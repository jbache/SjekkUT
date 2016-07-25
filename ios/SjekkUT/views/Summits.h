//
//  Summits.h
//  SjekkUt
//
//  Created by Henrik Hartz on 04/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Summits : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *checkinButton;
@property (weak, nonatomic) IBOutlet UILabel *checkedInNotificationLabel;
@property (weak, nonatomic) IBOutlet UIView *checkedInNotificationView;
@property (weak, nonatomic) IBOutlet UIButton *feedbackButton;

@end
