//
//  PlaceCell.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 27/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import AlamofireImage

extension NSDate {

    func timeAgo() -> String {
        let formatter = NSDateComponentsFormatter()
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Full
        formatter.includesApproximationPhrase = false
        formatter.includesTimeRemainingPhrase = false
        formatter.maximumUnitCount = 1
        formatter.allowedUnits = [.Minute, .Hour, .WeekOfYear, .Year]
        let dateRelativeString = formatter.stringFromDate(self, toDate: NSDate())
        return dateRelativeString!
    }
}

class PlaceCell: UITableViewCell {

    var isObserving = false
    var kObserveDistance = 0
    var kObserveCheckins = 0
    var kObserveImages = 0

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var climbCountLabel: UILabel!
    @IBOutlet weak var countyElevationLabel: UILabel!
    @IBOutlet weak var placeImageView: UIImageView!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!

    var place:Place? {
        didSet {
            stopObserving()
            nameLabel.text = place?.name
            countyElevationLabel.text = place?.countyElevationText()
            climbCountLabel.text = place?.checkinCountDescription()
            startObserving()
        }
    }

    deinit {
        stopObserving()
    }

    // MARK: private

    

    // MARK: cell
    override func prepareForReuse() {
        stopObserving()
        placeImageView.image = nil
        nameLabel.text = ""
        distanceLabel.text = ""
        climbCountLabel.text = ""
        countyElevationLabel.text = ""
        dateLabel.text = ""
    }

    // MARK: observing

    func startObserving() {
        if (isObserving == false) {
            place?.addObserver(self, forKeyPath: "distance", options: .Initial, context: &kObserveDistance)
            place?.addObserver(self, forKeyPath: "checkins", options: .Initial, context: &kObserveCheckins)
            place?.addObserver(self, forKeyPath: "images", options: .Initial, context: &kObserveImages)
            isObserving = true
        }
    }

    func stopObserving() {
        if (isObserving == true) {
            place?.removeObserver(self, forKeyPath: "distance")
            place?.removeObserver(self, forKeyPath: "checkins")
            place?.removeObserver(self, forKeyPath: "images")
            isObserving = false
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (context == &kObserveDistance) {
            distanceLabel.text = place?.distanceDescription()
        }
        if (context == &kObserveCheckins) {
            climbCountLabel.text = place?.checkinCountDescription()
            // if we have checked in
            if let lastCheckin = place?.lastCheckin() {
                checkButton.setTitle("\(Character(UnicodeScalar(0xf046)))", forState:.Normal)
                checkButton.setTitleColor(DntColor.red(), forState: .Normal)
                dateLabel.text = lastCheckin.date?.timeAgo()
            }
            else {
                checkButton.setTitle("\(Character(UnicodeScalar(0xf096)))", forState: .Normal)
                checkButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
                dateLabel.text = NSLocalizedString("Not climbed", comment:"no checkin label")
            }
        }
        if (context == &kObserveImages) {
            if let imageUrl = (place!.images?.firstObject as? DntImage)!.url {
                if let imageURL = NSURL(string: imageUrl) {
                    placeImageView.af_setImageWithURL(imageURL)
                }
            }
        }
    }
}