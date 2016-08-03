//
//  PlaceView.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 28/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

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

    // MARK: actions
    @IBAction func checkinClicked(sender: AnyObject) {
        sjekkUtApi.doPlaceVisit(place!)
    }

    @IBAction func shareClicked(sender: AnyObject) {
    }

    // MARK: viewcontroller
    override func viewDidLoad() {
        if (place != nil) {
            sjekkUtApi.getPlaceStats(place!)
        }
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

}