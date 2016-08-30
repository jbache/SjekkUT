//
//  PlaceView.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 28/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import AlamofireImage
import MapKit

class PlaceView : UITableViewController, UITextViewDelegate, UIWebViewDelegate {

    var place:Place? = nil
    var checkin:Checkin? = nil
    var vWebContentHeight:CGFloat = 0
    var kObserveLocation = 0

    let sjekkUtApi:SjekkUtApi = SjekkUtApi.instance

    @IBOutlet weak var mapView: UIImageView!
    @IBOutlet weak var descriptionTitle: UILabel!
    @IBOutlet weak var descriptionLabel: UITextView!
    @IBOutlet weak var checkinTitle: UILabel!
    @IBOutlet weak var checkinLabel: UITextView!
    @IBOutlet weak var checkinButton: UIButton!
    @IBOutlet weak var checkinCell: UITableViewCell!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet var placeCell: PlaceCell!
    @IBOutlet var descriptionWebView: UIWebView!
    @IBOutlet var descriptionWebViewHeight: NSLayoutConstraint!

    // MARK: private
    func didCheckInTo(notification:NSNotification) {
        let aCheckin = notification.object as! Checkin
        let aPlace = aCheckin.place! as Place
        _ = String(format:NSLocalizedString("Yay! Checked in to %@", comment: "check in notification text"), aPlace.name!)
    }

    func fetchAndSetupMapImage() {
        let mapApiKey = "maps.google.com.static.api_key".loadFileContents(inClass: self.dynamicType)
        let imageRequest = NSURLRequest(URL: place!.mapURLForView(mapView, withKey: mapApiKey!), cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: 60)
        mapView.af_setImageWithURLRequest(imageRequest, placeholderImage: nil, filter: nil, progress: nil, progressQueue: dispatch_get_main_queue(), imageTransition: .CrossDissolve(0.2), runImageTransitionIfCached: false, completion:nil)
    }

    // MARK: actions

    @IBAction func shareClicked(sender: AnyObject) {
        if let aURL = NSURL(string:(checkin?.url)!) {
            let activityView:UIActivityViewController = UIActivityViewController(activityItems: [aURL], applicationActivities: nil)
            activityView.completionWithItemsHandler = { activity, success, items, error in
                self.dismissViewControllerAnimated(true, completion:nil)
            }
            self.navigationController?.presentViewController(activityView, animated: true, completion: nil)
        }
    }

    @IBAction func readMoreClicked(sender: AnyObject) {
        if let aURL = place?.url!.URL() {
            UIApplication.sharedApplication().openURL(aURL)
        }

    }

    func showMap() {
        let aCoordinate = CLLocationCoordinate2DMake(
            (place?.latitude!.doubleValue)!,
            (place?.longitude!.doubleValue)!
        );

        let aPlacemark = MKPlacemark(coordinate: aCoordinate, addressDictionary: nil)

        let aMapItem = MKMapItem(placemark: aPlacemark)
        aMapItem.name = place?.name
        aMapItem.openInMapsWithLaunchOptions(nil)
    }

    // MARK: viewcontroller
    override func viewDidLoad() {
        shareButton.hidden = true

        if (place != nil) {
            placeCell.place = place
            TurbasenApi.instance.getPlace(place!)
        }

        checkin = checkin ?? place?.lastCheckin()

        // don't bother with sharing if there is nothing to share
        if let aCheckin = checkin {
            if let urlString = aCheckin.url {
                shareButton.hidden = !UIApplication.sharedApplication().canOpenURL(NSURL(string: urlString)!)
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        tableView.beginUpdates()
        fetchAndSetupMapImage()

        checkinLabel.text = place?.checkinDescription()
        checkinLabel.sizeToFit()

        tableView.endUpdates()
    }

    override func viewDidAppear(animated: Bool) {
        if place?.descriptionText != nil {
            tableView.beginUpdates()
            descriptionWebView.loadHTMLString((place?.descriptionText)!, baseURL: nil)
            tableView.endUpdates()
        }
    }

    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        #if DEBUG
            showMap()
        #endif
    }

    // MARK: observing

    func startObserving() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didCheckInTo), name: SjekkUtCheckedInNotification, object: nil)
        Location.instance().addObserver(self, forKeyPath: "currentLocation", options: .Initial, context: &kObserveLocation)
    }

    func stopObserving() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: SjekkUtCheckedInNotification, object: nil)
        Location.instance().removeObserver(self, forKeyPath: "currentLocation")
    }

    // MARK: table view

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.row == 2) {
            return vWebContentHeight == 0 ? 0 : super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
        if (indexPath.row == 3) {
            return vWebContentHeight
        }
        else if indexPath.row == 4 {
            if let aUrlString = place?.url {
                if aUrlString.URL() != nil {
                    return 44
                }
            }
            return 0
        }
        else if (indexPath.row == 6) {
            checkinCell.setNeedsLayout()
            checkinCell.layoutIfNeeded()
            let sizeMax = CGSizeMake(self.checkinLabel.frame.width, CGFloat.max)
            return checkinLabel.sizeThatFits(sizeMax).height + 16
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }

    // MARK: web view delegate
    func webViewDidFinishLoad(webView: UIWebView) {
        var frame = descriptionWebView.frame
        frame.size.height = 1
        descriptionWebView.frame = frame

        let fitSize:CGSize = descriptionWebView.sizeThatFits(CGSizeZero)
        frame.size = fitSize
        descriptionWebView.frame = frame

        tableView.beginUpdates()
        vWebContentHeight = fitSize.height + frame.origin.y * 2
        tableView.endUpdates()
    }

}