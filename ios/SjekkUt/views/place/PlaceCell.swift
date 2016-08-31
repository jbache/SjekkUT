//
//  PlaceCell.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 27/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireImage

class PlaceCell: UITableViewCell {

    var isObserving = false
    var kObserveDistance = 0
    var kObserveCheckins = 0
    var kObserveImages = 0
    var kObserveUrl = 0

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var climbCountLabel: UILabel!
    @IBOutlet weak var countyElevationLabel: UILabel!
    @IBOutlet weak var placeImageView: UIImageView!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet var homepageUrlButton: UIButton!

    var imageRequest: Request?

    var foregroundImage: UIImage? = nil {
        didSet {
            placeImageView.image = foregroundImage
        }
    }

    var place:Place? {
        willSet {
            stopObserving()
        }
        didSet {
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

    @IBAction func homepageClicked(sender: AnyObject) {
        if let homepageURL = place?.url?.URL() {
            UIApplication.sharedApplication().openURL(homepageURL)
        }
    }

    // MARK: cell
    override func prepareForReuse() {
        stopObserving()
        nameLabel.text = ""
        distanceLabel.text = ""
        climbCountLabel.text = ""
        countyElevationLabel.text = ""
        dateLabel.text = ""
    }

    // MARK: observing

    func startObserving() {
        if (isObserving == false && place != nil) {
            place?.addObserver(self, forKeyPath: "distance", options: .Initial, context: &kObserveDistance)
            place?.addObserver(self, forKeyPath: "checkins", options: .Initial, context: &kObserveCheckins)
            place?.addObserver(self, forKeyPath: "images", options: .Initial, context: &kObserveImages)
            place?.addObserver(self, forKeyPath: "url", options: .Initial, context: &kObserveUrl)
            isObserving = true
        }
    }

    func stopObserving() {
        if (isObserving == true && place != nil) {
            place?.removeObserver(self, forKeyPath: "distance")
            place?.removeObserver(self, forKeyPath: "checkins")
            place?.removeObserver(self, forKeyPath: "images")
            place?.removeObserver(self, forKeyPath: "url")
            isObserving = false
        }
        if imageRequest != nil {
            imageRequest!.cancel()
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
                let dateRelativeString = lastCheckin.date?.timeAgo()
                dateLabel.text = NSLocalizedString("\(dateRelativeString!) ago",comment:"time since")
            }
            else {
                checkButton.setTitle("\(Character(UnicodeScalar(0xf096)))", forState: .Normal)
                checkButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
                dateLabel.text = NSLocalizedString("Not climbed", comment:"no checkin label")
            }
        }
        if (context == &kObserveImages) {
            let loadPlaceholder = {
                self.foregroundImage = UIImage(named:"project-foreground-fallback")
            }

            if let imageURL:NSURL = place!.foregroundImageURLforSize(placeImageView.bounds.size) {
                imageRequest = Alamofire.request(.GET,imageURL)
                    .validate(statusCode:200..<300)
                    .responseImage { response in
                        switch(response.result) {
                        case .Success:
                            if let image = response.result.value {
                                self.foregroundImage = image
                            }
                        case .Failure:
                            loadPlaceholder()
                        }
                }
            }
            else {
                loadPlaceholder()
            }
        }
        if (context == &kObserveUrl) {
            if let aButton = homepageUrlButton {
                if (place?.url != nil && place?.url?.characters.count > 0) {
                    aButton.hidden = false
                }
                else {
                    aButton.hidden = true
                }
            }
        }
    }
}