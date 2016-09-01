//
//  CheckinButton.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 25/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

class CheckinButton: UIButton {

    let locationController = Location.instance()
    var kObserveLocation = 0
    var isObserving = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        titleLabel?.lineBreakMode = .ByWordWrapping
        titleLabel!.numberOfLines = 3
        titleLabel?.textAlignment = .Center
        titleLabel?.font = UIFont.systemFontOfSize(12)
        alpha = 0

        backgroundColor = UIColor.grayColor()
        setBackgroundImage(DntColor.red().imageWithSize(self.bounds.size), forState: .Normal)
        setBackgroundImage(UIColor.grayColor().imageWithSize(self.bounds.size), forState: .Disabled)

        startObserving()

        addTarget(self, action: #selector(checkinClicked), forControlEvents: .TouchUpInside)
    }

    deinit {

        locationController.stopUpdate()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.size.width / 2
        self.layer.masksToBounds = true
    }

    // MARK: observer

    func startObserving() {
        if (!isObserving) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateButton), name: kSjekkUtNotificationLocationChanged, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateButton), name: SjekkUtCheckedInNotification, object: nil)

            isObserving = true
        }
    }

    func stopObserving() {
        if (isObserving) {
            NSNotificationCenter.defaultCenter().removeObserver(self)
            isObserving = false
        }
    }

    func updateButton() {
        var theAlpha:CGFloat = 0
        if let nearestPlace = nearestPlace() {
            let enabledString = NSLocalizedString("Visit \(nearestPlace.name!)",
                                                  comment:"check in button title")
            let disabledDistanceString = NSLocalizedString("\(nearestPlace.distanceDescription()) left",
                                                           comment:"distance checkin button title")
            let disabledTimeString = NSLocalizedString("Visited \(nearestPlace.name!) \(nearestPlace.lastCheckin().timeAgo()) ago",
                                                       comment: "time checkin button title")

            self.setTitle(enabledString , forState:.Normal)
            self.setTitle(nearestPlace.canCheckinTime() ? disabledDistanceString : disabledTimeString, forState: .Disabled)
            self.enabled = nearestPlace.canCheckIn()
            theAlpha = 1
        }
        else {
            theAlpha = 0
            enabled = false
        }
        // hide or show the button
        UIView.animateWithDuration(kSjekkUtConstantAnimationDuration) { 
            self.alpha = theAlpha
        }
    }

    func nearestPlace() -> Place? {
        let allPlaces = Place.allEntities() as NSArray

        let sortedPlaces = allPlaces.sortedArrayUsingDescriptors( [NSSortDescriptor(key: "distance", ascending: true)] ) as! [Place]

        if let firstPlace = sortedPlaces.first {
            return firstPlace
        }
        return nil
    }

    func checkinClicked() {
        let aPlaceSearchView = PlaceSearch.storyboardInstance("PlaceSearch") as! PlaceSearch
        aPlaceSearchView.place = nearestPlace()
        (UIApplication.sharedApplication().keyWindow?.rootViewController as! UINavigationController).pushViewController(aPlaceSearchView, animated: true)
    }
}