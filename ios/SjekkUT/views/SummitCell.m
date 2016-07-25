//
//  SummitCell.m
//  SjekkUt
//
//  Created by Henrik Hartz on 05/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "Defines.h"
#import "SummitCell.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
//#import <FontAwesome/NSString+FontAwesome.h>

#define UIColorFromRGB(rgbValue)                                         \
    [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0 \
                    green:((float)((rgbValue & 0x00FF00) >> 8)) / 255.0  \
                     blue:((float)((rgbValue & 0x0000FF) >> 0)) / 255.0  \
                    alpha:1.0]

@implementation SummitCell

@synthesize summit;

- (void)prepareForReuse
{
    [self.iconView setImage:nil];
}

- (void)setSummit:(Summit *)newValue
{
    summit = newValue;

    self.nameLabel.text = summit.name;
    self.countyElevationLabel.text = [NSString stringWithFormat:@"%@, %@", summit.countyName, summit.elevationDescription];
    self.climbCountLabel.text = summit.checkinCountDescription;
    [self.iconView setImageWithURL:summit.imageURL];
    self.distanceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Distance to destination: %@", @"distance"), summit.distanceDescription];
    self.distanceLabel.hidden = NO;

    if (summit.haveCheckedIn)
    {
        //        [self.checkButton setTitle:[NSString fontAwesomeIconStringForEnum:FAIconCheck]
        //                          forState:UIControlStateNormal];
        [self.checkButton setTitleColor:dntRed
                               forState:UIControlStateNormal];
        self.dateLabel.text = summit.checkinTimeAgo;
    }
    else
    {
        //        [self.checkButton setTitle:[NSString fontAwesomeIconStringForEnum:FAIconCheckEmpty]
        //                          forState:UIControlStateNormal];
        [self.checkButton setTitleColor:[UIColor blackColor]
                               forState:UIControlStateNormal];
        self.dateLabel.text = NSLocalizedString(@"Not climbed", @"no checkin label");
    }
}

@end
