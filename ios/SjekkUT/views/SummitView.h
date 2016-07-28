//
//  SummitView.h
//  SjekkUt
//
//  Created by Henrik Hartz on 05/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "Place.h"

#import <UIKit/UIKit.h>

typedef enum {
    SjekkUtSummitStateNormal,
    //  SjekkUtSummitStateAlreadyCheckedIn,
    SjekkUtSummitStateCheckinAvailable,
    SjekkUtSummitStateCheckedIn
} SjekkUtSummitState;

@interface SummitView : UITableViewController <UITextViewDelegate>

@property (weak, nonatomic) Place *place;
@property (weak, nonatomic) Checkin *checkin;
@property (readonly, nonatomic) SjekkUtSummitState state;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *countyAltitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *climberCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionTitle;
@property (weak, nonatomic) IBOutlet UITextView *descriptionLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell *checkinCell;
@property (weak, nonatomic) IBOutlet UILabel *checkinTitle;
@property (weak, nonatomic) IBOutlet UITextView *checkinLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkinButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIImageView *mapView;

@end
