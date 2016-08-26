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

class PlaceView : UITableViewController, UITextViewDelegate {

    var place:Place? = nil
    var checkin:Checkin? = nil

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
    @IBAction func checkinClicked(sender: AnyObject) {
        sjekkUtApi.doPlaceCheckin(place!) { result in
            
        }
    }

    @IBAction func shareClicked(sender: AnyObject) {
        if let aURL = NSURL(string:(checkin?.url)!) {
            let activityView:UIActivityViewController = UIActivityViewController(activityItems: [aURL], applicationActivities: nil)
            activityView.completionWithItemsHandler = { activity, success, items, error in
                self.dismissViewControllerAnimated(true, completion:nil)
            }
            self.navigationController?.presentViewController(activityView, animated: true, completion: nil)
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
            sjekkUtApi.getPlaceCheckins(place!)
            placeCell.place = place
        }

        checkin = checkin ?? place?.lastCheckinForUser(DntApi.instance.user!)

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

        descriptionLabel.text = place?.descriptionText
        descriptionLabel.sizeToFit()
        checkinLabel.text = place?.checkinDescription()
        checkinLabel.sizeToFit()

        tableView.endUpdates()
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
        if (indexPath.row == 3) {
            let sizeMax = CGSizeMake(self.descriptionLabel.frame.width, CGFloat.max)
            return descriptionLabel.sizeThatFits(sizeMax).height + 16
        }
        else if (indexPath.row == 5) {
            checkinCell.setNeedsLayout()
            checkinCell.layoutIfNeeded()
            let sizeMax = CGSizeMake(self.checkinLabel.frame.width, CGFloat.max)
            return checkinLabel.sizeThatFits(sizeMax).height + 16
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }

}