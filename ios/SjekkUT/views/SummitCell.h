//
//  SummitCell.h
//  SjekkUt
//
//  Created by Henrik Hartz on 05/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "Summit+Extension.h"
#import <UIKit/UIKit.h>

@interface SummitCell : UITableViewCell

@property (retain, nonatomic) Summit *summit;

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *countyElevationLabel;
@property (weak, nonatomic) IBOutlet UILabel *climbCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkButton;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end
