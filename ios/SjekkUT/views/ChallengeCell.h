//
//  ChallengeCell.h
//  SjekkUt
//
//  Created by Henrik Hartz on 20/05/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Challenge+Extension.h"

@interface ChallengeCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *challengeLogo;
@property (weak, nonatomic) IBOutlet UIImageView *challengeFooter;
@property (weak, nonatomic) IBOutlet UIButton *readMoreButton;
@property (weak, nonatomic) IBOutlet UIButton *joinChallengeButton;
@property (weak, nonatomic) IBOutlet UILabel *challengeStatusLabel;

@property (weak, nonatomic) Challenge *challenge;

- (IBAction)joinChallengeClicked:(id)sender;

@end
