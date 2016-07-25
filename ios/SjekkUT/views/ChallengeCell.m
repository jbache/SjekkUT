//
//  ChallengeCell.m
//  SjekkUt
//
//  Created by Henrik Hartz on 20/05/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>

#import "Backend.h"
#import "ChallengeCell.h"
#import "NSString+URL.h"

@implementation ChallengeCell
{
    BOOL observing;
}

- (id)init
{
    if ((self = [super init]) == nil)
        return nil;

    return self;
}

- (void)dealloc
{
    [self removeObservers];
}

- (void)awakeFromNib
{
    self.readMoreButton.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)prepareForReuse
{
    [self.challengeFooter setImage:nil];
    [self.challengeLogo setImage:nil];
    [self removeObservers];
}

- (void)setChallenge:(Challenge *)challenge
{
    _challenge = challenge;
    [self.challengeLogo setImageWithURL:[challenge.logoUrl URL]];
    [self.challengeFooter setImageWithURL:[challenge.footerUrl URL]];
    self.readMoreButton.alpha = (!_challenge.infoUrl || !_challenge.infoUrl.length) ? 0 : 1;

    [_challenge addObserver:self forKeyPath:@"participating" options:NSKeyValueObservingOptionInitial context:nil];
    [_challenge addObserver:self forKeyPath:@"userProgress" options:NSKeyValueObservingOptionInitial context:nil];
    observing = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"participating"])
    {
        self.joinChallengeButton.alpha = _challenge.participating.boolValue ? 0 : 1;
        self.challengeStatusLabel.alpha = _challenge.participating.boolValue ? 1 : 0;
    }
    if ([keyPath isEqualToString:@"userProgress"])
    {
        if (_challenge.summitedCount == _challenge.summits.count)
        {
            NSString *format = NSLocalizedString(@"Congratulations, you have visited all %ld summits!", @"all summits summited in challenge");
            self.challengeStatusLabel.text = [NSString stringWithFormat:format,
                                                                        (long)_challenge.summits.count];
        }
        else
        {
            NSString *format = NSLocalizedString(@"You have summited %ld of %ld so far!",
                                                 @"count summits in challenge");
            self.challengeStatusLabel.text = [NSString stringWithFormat:format,
                                                                        (long)_challenge.summitedCount,
                                                                        (long)_challenge.summits.count];
        }
    }
}

- (void)removeObservers
{
    if (observing)
    {
        [_challenge removeObserver:self forKeyPath:@"participating"];
        [_challenge removeObserver:self forKeyPath:@"userProgress"];
        observing = NO;
    }
}

- (IBAction)readMoreClicked:(id)sender
{
    [[UIApplication sharedApplication] openURL:[_challenge.infoUrl URL]];
}

- (IBAction)joinChallengeClicked:(id)sender
{
    [backend joinChallenge:_challenge];
}

@end
