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
    var showingPanel: Bool { get set }
    func showInfo(aMessage:CheckinMessage)
    func hideInfo()
}

class CheckinButton: UIButton {

    let locationController = Location.instance()
    var kObserveLocation = 0
    var isObserving = false
    var delegate:CheckinButtonDelegate!
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

        // if the panel is displaying, hide it
        if delegate.showingPanel {
            delegate.hideInfo()
        }
        else if CLLocationManager.authorizationStatus() != .AuthorizedWhenInUse {
            setTitle(noGpsMessage().title, forState: .Normal)
            delegate.showInfo(noGpsMessage())
        }
        else if let aPlace = nearestPlace() {
            // prevent double-tapping checkin
            if aPlace.canCheckIn() {
                delegate.showInfo(self.visitingMessage())
                enabled = false
                SjekkUtApi.instance.doPlaceCheckin(aPlace) {
                    response in
                    switch response.result {
                    case .Success:
                        self.delegate!.showInfo(self.visitedMessage())
                    case .Failure(let error):
                        // try to parse the message from API
                        var aMessage:String? = nil
                        do {
                            let JSON = try NSJSONSerialization.JSONObjectWithData(response.data!, options:NSJSONReadingOptions(rawValue: 0)) as! NSDictionary
                            aMessage = JSON["message"] as? String
                        }
                        catch let JSONError as NSError {
                            print("error: \(JSONError)")
                        }
                        self.delegate!.showInfo(self.failedMessage(aMessage ?? error.localizedFailureReason!))
                    }
                    // re-enable checkin button
                    self.enabled = true
                }
            }
            else {
                delegate.showInfo(disabledMessage())
            }
        }
    }

    // MARK: strings

    func noGpsMessage() -> CheckinMessage {
        let title = NSLocalizedString("No GPS", comment: "No GPS signal title")
        let message = NSLocalizedString("We need GPS to register visit. Please turn this on in Settings", comment: "No GPS signal message")
        return (title, message)
    }

    func visitingMessage() -> CheckinMessage {
        let titleString = NSLocalizedString("Registering visit", comment: "title of panel when visiting")
        let messageString = String.localizedStringWithFormat(NSLocalizedString("Visiting %@, please wait..", comment: "message of panel when visiting"), place!.name!)
        return (titleString, messageString)
    }

    func visitedMessage() -> CheckinMessage {
        let titleString = String.localizedStringWithFormat(NSLocalizedString("Visited %@", comment: "title of panel after visiting"),place!.name!)
        let messageString = String.localizedStringWithFormat(NSLocalizedString("Ok, we have you visiting %@. Good job!", comment: "message of panel after visiting"), place!.name!)
        return (titleString, messageString)
    }

    func enabledMessage() -> CheckinMessage {
        let aTitle = String.localizedStringWithFormat(NSLocalizedString("Visit %@", comment:"visit title"), place!.name!)
        let aMessage = String.localizedStringWithFormat(NSLocalizedString("You can now visit %@!", comment:"visit message"), place!.name!)
        return (aTitle, aMessage)
    }

    func disabledMessage() -> CheckinMessage {
        var title = NSLocalizedString("Visit registered", comment: "title of visit panel when not possible to visit")
        var message = String.localizedStringWithFormat(NSLocalizedString("You visited %@ %@ ago", comment: "message of visit panel when not possible to visit"), place!.name!, place!.lastCheckin().timeAgo())
        if place!.canCheckinTime() {
            title = String.localizedStringWithFormat(NSLocalizedString("%@ left", comment:"distance visit button title"), place!.distanceDescription())
            message = String.localizedStringWithFormat(NSLocalizedString("Nearest post is %@.", comment:"distance visit button message"), place!.name!)
        }

        return (title,message)
    }

    func failedMessage(anError:String) -> CheckinMessage {
        let title = NSLocalizedString("Can't register visit", comment: "title of panel if visit fails")
        let message = String.localizedStringWithFormat(NSLocalizedString("Something wrong happened: %@.", comment: "message of panel failing to visit"), anError)
        return (title, message)
    }
}