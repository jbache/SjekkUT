//
//  CheckinButton.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 25/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

typealias CheckinMessage = (title:String, message:String)

protocol CheckinButtonDelegate {
    func showInfo(aMessage:CheckinMessage)
    func hideInfo()
}

class CheckinButton: UIButton {

    let locationController = Location.instance()
    var kObserveLocation = 0
    var isObserving = false
    var delegate:CheckinButtonDelegate? = nil
    var updateTimer:NSTimer!
    var place:Place?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        setTitleColor(UIColor.whiteColor(), forState: .Normal)
        
        titleLabel?.lineBreakMode = .ByWordWrapping
        titleLabel!.numberOfLines = 3
        titleLabel?.textAlignment = .Center
        titleLabel?.font = UIFont.systemFontOfSize(12)

        updateButton()
        startObserving()
        updateTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: #selector(updateButton), userInfo: nil, repeats: true)
        addTarget(self, action: #selector(checkinClicked), forControlEvents: .TouchUpInside)
    }

    deinit {
        locationController.stopUpdate()
        updateTimer.invalidate()
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
        var isEnabled:Bool = false
        var theAlpha = 1

        place = nearestPlace()

        if CLLocationManager.authorizationStatus() != .AuthorizedWhenInUse {
            setTitle(noGpsMessage().title, forState: .Normal)
        }
        else if let aPlace = place {
            isEnabled = aPlace.canCheckIn()
            if isEnabled {
                self.setTitle(enabledMessage().title, forState:.Normal)
            }
            else {
                self.setTitle(disabledMessage().title, forState: .Normal)
            }
        }
        else {
            theAlpha = 0
        }

        // hide or show the button
        UIView.animateWithDuration(kSjekkUtConstantAnimationDuration) { 
            self.alpha = CGFloat(theAlpha)
            self.setBackgroundImage(isEnabled ? DntColor.red().imageWithSize(self.bounds.size) :
                                                UIColor.grayColor().imageWithSize(self.bounds.size), forState: .Normal)
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
        if CLLocationManager.authorizationStatus() != .AuthorizedWhenInUse {
            setTitle(noGpsMessage().title, forState: .Normal)
            delegate?.showInfo(noGpsMessage())
        }
        else if let aPlace = nearestPlace() {
            if aPlace.canCheckIn() {
                delegate?.showInfo(self.visitingMessage())
                SjekkUtApi.instance.doPlaceCheckin(aPlace) {
                    result in
                    switch result {
                    case .Success:
                        self.delegate!.showInfo(self.visitedMessage())
                    case .Failure(let error):
                        self.delegate!.showInfo(self.failedMessage(error))
                    }
                }
            }
            else {
                delegate?.showInfo(disabledMessage())
            }
        }
    }

    // MARK: strings

    func noGpsMessage() -> CheckinMessage {
        return (NSLocalizedString("No GPS", comment: "No GPS signal title"),
                NSLocalizedString("We need GPS to register visit. Please turn this on in Settings", comment: "No GPS signal message"))
    }

    func visitingMessage() -> CheckinMessage {
        let titleString = NSLocalizedString("Registering visit", comment: "title of panel when visiting")
        let messageString = NSLocalizedString("Visiting \(place!.name!), please wait..", comment: "message of panel when visiting")
        return (titleString, messageString)
    }

    func visitedMessage() -> CheckinMessage {
        return (NSLocalizedString("Visited \(place!.name!)", comment: "title of panel after visiting"),
                NSLocalizedString("Ok, we have you visiting \(place!.name!). Good job!", comment: "message of panel after visiting"))
    }

    func enabledMessage() -> CheckinMessage {
        return (NSLocalizedString("Visit \(place!.name!)", comment:"visit title"),
                NSLocalizedString("You can now visit \(place!.name!)!", comment:"visit message"))
    }

    func disabledMessage() -> CheckinMessage {
        if place!.canCheckinTime() {
//            let distanceLimit = "200m"
            return (NSLocalizedString("\(place!.distanceDescription()) left", comment:"distance visit button title"),
                    NSLocalizedString("Nearest post is \(place!.name).", comment:"distance visit button message"))
        }
        else {
            return (NSLocalizedString("Visit registered", comment: "title of visit panel when not possible to visit"),
                    NSLocalizedString("You visited \(place!.name!) \(place!.lastCheckin().timeAgo()) ago", comment: "message of visit panel when not possible to visit"))
        }
    }

    func failedMessage(anError:NSError) -> CheckinMessage {
        return (NSLocalizedString("Can't register visit", comment: "title of panel if visit fails"),
                NSLocalizedString("Something wrong happened: \(anError.localizedDescription).", comment: "message of panel failing to visit"))
    }
}