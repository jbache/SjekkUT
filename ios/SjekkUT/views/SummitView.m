//
//  SummitView.m
//  SjekkUt
//
//  Created by Henrik Hartz on 05/02/15.
//  Copyright (c) 2015 Den Norske Turistforening. All rights reserved.
//

#import "AFNetworkActivityIndicatorManager.h"
#import "Backend.h"
#import "Checkin+Extension.h"
#import "Checkin.h"
#import "CheckinStatistics+Extension.h"
#import "Defines.h"
#import "Location.h"
#import "NSString+FontAwesome.h"
#import "NetworkController.h"
#import "SummitView.h"
#import "UIImageView+AFNetworking.h"

static BOOL toggle = NO;

@interface SummitView ()

@end

@implementation SummitView
{
    BOOL observing;
    BOOL hideCheckinButton;
    BOOL justCheckedIn;
}

@synthesize place;

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    toggle = !toggle;

    if (self.checkin)
    {
        self.summit = self.checkin.summit;
    }

    if (![self.summit canCheckIn])
    {
        justCheckedIn = YES;
    }

    [network updateStatisticsFor:self.summit];

    [self.tableView beginUpdates];

    [self setupDescription];
    [self setupNavbar];
    [self setupHeader];
    [self setupTable];
    [self updateCheckinButton];

    [self.tableView endUpdates];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!observing)
    {
        [self addObserver:self forKeyPath:@"checkin" options:NSKeyValueObservingOptionInitial context:nil];
        [self.summit addObserver:self forKeyPath:@"checkin"
                         options:NSKeyValueObservingOptionInitial
                         context:nil];
        [self.summit addObserver:self forKeyPath:@"statistics"
                         options:NSKeyValueObservingOptionInitial
                         context:nil];

        observing = YES;
    }

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    // display the summit map after the view has finished layout
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[self.summit mapURLForView:self.mapView]
                                                  cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                              timeoutInterval:60];

    __weak typeof(self) weakSelf = self;

    [self.mapView setImageWithURLRequest:imageRequest
                        placeholderImage:nil
                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {

                                     [weakSelf.mapView setImage:image];

                                     CAShapeLayer *scaleLayer = [CAShapeLayer layer];

                                     CGRect mapBounds = [weakSelf.mapView bounds];

                                     CGFloat scaleRatio = (image.size.width * image.scale) / mapBounds.size.width;

                                     scaleRatio /= 2;

                                     // Give the layer the same bounds as your image view
                                     [scaleLayer setBounds:CGRectMake(0.0f, 0.0f, mapBounds.size.width,
                                                                      mapBounds.size.height)];

                                     // Position the circle anywhere you like, but this will center it
                                     // In the parent layer, which will be your image view's root layer
                                     [scaleLayer setPosition:CGPointMake([weakSelf.mapView bounds].size.width / 2.0f,
                                                                         [weakSelf.mapView bounds].size.height / 2.0f)];

                                     UIBezierPath *bezierPath = [UIBezierPath bezierPath];

                                     CGFloat scaleWidth = 75.0f;
                                     CGFloat scaleHeight = 10.0f;
                                     CGFloat scaleMargin = 10.0f;
                                     CGFloat scaleX = mapBounds.size.width - scaleWidth - scaleMargin;
                                     CGFloat scaleY = mapBounds.size.height - scaleHeight - scaleMargin;

                                     // create vertical tick marks indicating scale scope
                                     // create a horizontal line indicating scale
                                     [bezierPath moveToPoint:CGPointMake(scaleX, scaleY)];
                                     [bezierPath addLineToPoint:CGPointMake(scaleX, scaleY + scaleHeight)];
                                     [bezierPath addLineToPoint:CGPointMake(scaleX + scaleWidth, scaleY + scaleHeight)];
                                     [bezierPath addLineToPoint:CGPointMake(scaleX + scaleWidth, scaleY)];

                                     // Set the path on the layer
                                     [scaleLayer setPath:[bezierPath CGPath]];
                                     // Set the stroke color
                                     [scaleLayer setStrokeColor:[[UIColor darkGrayColor] CGColor]];
                                     [scaleLayer setFillColor:[[UIColor clearColor] CGColor]];
                                     // Set the stroke line width
                                     [scaleLayer setLineWidth:2.0f];

                                     // calculate the absolute size of scaleWidth

                                     CGFloat pixelsPrM = 156543.03392 * cosf(locationBackend.currentLocation.coordinate.latitude * M_PI / 180) / powf(2.0f, SjekkUtMapZoomLevel);

                                     CGFloat scaleSize = scaleWidth * pixelsPrM * scaleRatio;

                                     // draw the absolute size of the line
                                     CATextLayer *textLayer = [[CATextLayer alloc] init];
                                     textLayer.contentsScale = [UIScreen mainScreen].scale;
                                     textLayer.string = [NSString stringWithFormat:@"%.f m", scaleSize];
                                     textLayer.font = CFBridgingRetain([UIFont boldSystemFontOfSize:12].fontName);
                                     textLayer.fontSize = 12;
                                     textLayer.foregroundColor = [UIColor blackColor].CGColor;
                                     textLayer.alignmentMode = kCAAlignmentCenter;
                                     textLayer.foregroundColor = [[UIColor darkGrayColor] CGColor];
                                     textLayer.frame = CGRectMake(scaleX, scaleY - scaleHeight, scaleWidth, scaleHeight * 2);

                                     [scaleLayer addSublayer:textLayer];

                                     // Add the sublayer to the image view's layer tree
                                     [[weakSelf.mapView layer] addSublayer:scaleLayer];

                                 }
                                 failure:nil];

    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (observing)
    {
        [self.summit removeObserver:self forKeyPath:@"checkin"];
        [self.summit removeObserver:self forKeyPath:@"statistics"];
        [self removeObserver:self forKeyPath:@"checkin"];
        observing = NO;
    }
    [super viewWillDisappear:animated];
}

#pragma mark UI setup

- (void)setupTable
{
    self.tableView.estimatedRowHeight = 65.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)setupNavbar
{
    self.navigationItem.title = [self title];
    [self.shareButton setTitle:[NSString fontAwesomeIconStringForEnum:FAIconShare]
                      forState:UIControlStateNormal];
}

- (void)setupHeader
{
    [self.iconView setImageWithURL:[NSURL URLWithString:summit.imageUrl]];
    self.nameLabel.text = summit.name;
    self.countyAltitudeLabel.text = [NSString stringWithFormat:@"%@, %@", summit.countyName, summit.elevationDescription];
    self.climberCountLabel.text = summit.checkinCountDescription;
    self.distanceLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Distance to destination: %@", @"distance"), summit.distanceDescription];
    self.distanceLabel.hidden = locationBackend.currentLocation == nil;
    self.progressView.progress = 0;
    self.descriptionTitle.text = NSLocalizedString(@"Description", @"description heading in summit view");
    self.checkinTitle.text = NSLocalizedString(@"Checkin", @"checkin heading in summit view");
}

- (void)setupDescription
{
    self.descriptionLabel.text = summit.information;
    [self.descriptionLabel sizeToFit];

    NSMutableString *checkinDescription = [@"" mutableCopy];

    if (self.summit.statistics != nil)
    {
        [checkinDescription appendFormat:@"%@\n\n", self.summit.statistics.verboseDescription];
    }

    if ([self.summit canCheckIn])
    {
        [checkinDescription appendString:NSLocalizedString(@"You can check in.", @"can check in")];
    }
    else
    {
        if (![self.summit canCheckinTime] && ![self.summit canCheckinDistance])
        {
            [checkinDescription appendString:NSLocalizedString(@"You have to be 200 meter from the summit and wait 24 hours before you can check in.", @"can't check in time and distance")];
        }
        else if (![self.summit canCheckinTime])
        {
            [checkinDescription appendString:NSLocalizedString(@"You have to wait 24 hours before you can check in.", @"can't check in time")];
        }
        else if (![self.summit canCheckinDistance])
        {
            [checkinDescription appendString:NSLocalizedString(@"You have to be 200 meter from the summit before you can check in.", @"can't check in distance")];
        }
    }

    self.checkinLabel.text = checkinDescription;
    [self.checkinLabel sizeToFit];
}

#pragma mark observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"checkin"])
    {
        [self updateCheckinButton];
        [self updateShareButton];
    }
    if ([keyPath isEqualToString:@"statistics"])
    {
        [self.tableView beginUpdates];
        [self setupDescription];
        [self.tableView endUpdates];
    }
}

- (void)updateCheckinButton
{
    [self.checkinButton setTitle:[self checkinButtonTitle]
                        forState:UIControlStateNormal];
    [self.checkinButton setBackgroundColor:[self checkinButtonColor]];
    self.checkinButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.checkinButton.titleLabel.numberOfLines = 2;
    self.checkinButton.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)updateShareButton
{
    self.shareButton.hidden = !(self.checkin || self.summit.checkins.count > 0);
}

#pragma mark UITableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.row == 1 || indexPath.row == 2) && summit.information.length == 0)
    {
        return 0;
    }
    else if (indexPath.row == 2)
    {
        CGSize sizeMax = CGSizeMake(self.descriptionLabel.frame.size.width, CGFLOAT_MAX);
        return [self.descriptionLabel sizeThatFits:sizeMax].height + 16;
    }
    else if (indexPath.row == 4)
    {
        [self.checkinCell setNeedsLayout];
        [self.checkinCell layoutIfNeeded];
        CGSize sizeMax = CGSizeMake(self.checkinLabel.frame.size.width, CGFLOAT_MAX);
        CGSize targetSize = [self.checkinLabel sizeThatFits:sizeMax];
        return targetSize.height + 16;
    }
    else if (indexPath.row == 5)
    {
        if (hideCheckinButton)
            return 0;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

#pragma mark UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    return YES;
}

#pragma mark -

- (NSString *)title
{
    switch ([self state])
    {
        case SjekkUtSummitStateCheckinAvailable:
        case SjekkUtSummitStateNormal:
            return self.summit.name;
        case SjekkUtSummitStateCheckedIn:
            return NSLocalizedString(@"Congratulations!", @"Summit found title");
    }
    return @"";
}

- (NSString *)checkinButtonTitle
{
    return justCheckedIn ? NSLocalizedString(@"OK", @"just checked in title")
                         : NSLocalizedString(@"Check In!", @"checkin available button title");
}

- (UIColor *)checkinButtonColor
{
    return justCheckedIn ? dntLightGray : dntRed;
}

- (NSString *)information
{
    return summit.information;
}

- (IBAction)shareClicked:(id)sender
{
    NSString *appName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
    if (!appName)
    {
        appName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    }

    NSString *format = NSLocalizedString(@"I summited %@ using %@, %@!", @"Share text");
    NSString *shareText = [NSString stringWithFormat:format, self.summit.name, appName, self.summit.checkinTimeAgo];
    [self shareText:shareText
              image:nil
                url:[NSURL URLWithString:summit.infoUrl]];
}

- (void)shareText:(NSString *)text image:(UIImage *)image url:(NSURL *)url
{
    NSMutableArray *items = [@[] mutableCopy];
    if (text)
        [items addObject:text];
    if (image)
        [items addObject:image];
    if (url)
        [items addObject:url];
    UIActivityViewController *shareController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    [self presentViewController:shareController animated:YES completion:nil];
}

- (IBAction)checkinClicked
{
    if (justCheckedIn)
    {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }

    __weak typeof(self) weakSelf = self;

    void (^finally)(void) = ^{

    };
    void (^postCheckin)(Checkin *) = ^(Checkin *checkin) {
        weakSelf.checkin = checkin;
        [weakSelf.tableView beginUpdates];
        [weakSelf setupDescription];
        justCheckedIn = YES;
        [self updateCheckinButton];
        [weakSelf.tableView endUpdates];
        finally();
    };
    void (^failHandler)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError *err) {
        network.failHandler(task, err);
        finally();
    };

    switch ([self state])
    {
        case SjekkUtSummitStateCheckinAvailable:
        case SjekkUtSummitStateNormal:
        {
            [locationBackend getSingleUpdate:^(CLLocation *location) {
                [network checkinTo:summit and:postCheckin
                                or:failHandler];
            }];
            break;
        }
        default:

            break;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SjekkUtLocationTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakSelf && locationBackend.singleUpdateInProgress)
        {
            [defaultNotifyer postNotificationName:SjekkUtTimeoutNotification object:nil];
        }
    });
}

- (BOOL)checkinAvailable
{
    return !self.checkin;
}

- (SjekkUtSummitState)state
{
    if (self.checkin && !self.summit)
    {
        return SjekkUtSummitStateCheckedIn;
    }

    return [self checkinAvailable] ? SjekkUtSummitStateCheckinAvailable : SjekkUtSummitStateNormal;
}

@end
