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

    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var mapView: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var countyAltitudeLabel: UILabel!
    @IBOutlet weak var climberCountLabel: UILabel!
    @IBOutlet weak var descriptionTitle: UILabel!
    @IBOutlet weak var descriptionLabel: UITextView!
    @IBOutlet weak var checkinTitle: UILabel!
    @IBOutlet weak var checkinLabel: UITextView!
    @IBOutlet weak var checkinButton: UIButton!
    @IBOutlet weak var checkinCell: UITableViewCell!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var shareButton: UIButton!

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
        sjekkUtApi.doPlaceVisit(place!) { result in
            
        }
    }

    @IBAction func shareClicked(sender: AnyObject) {
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
        if (place != nil) {
            sjekkUtApi.getPlaceCheckins(place!)
            sjekkUtApi.getPlaceStats(place!)
        }
    }

    override func viewWillAppear(animated: Bool) {
        tableView.beginUpdates()
        fetchAndSetupMapImage()

        nameLabel.text = place?.name
        countyAltitudeLabel.text = place?.countyElevationText()
        climberCountLabel.text = place?.checkinCountDescription()

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
        if (indexPath.row == 2) {
            let sizeMax = CGSizeMake(self.descriptionLabel.frame.width, CGFloat.max)
            return descriptionLabel.sizeThatFits(sizeMax).height + 16
        }
        else if (indexPath.row == 4) {
            checkinCell.setNeedsLayout()
            checkinCell.layoutIfNeeded()
            let sizeMax = CGSizeMake(self.checkinLabel.frame.width, CGFloat.max)
            return checkinLabel.sizeThatFits(sizeMax).height + 16
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }

}