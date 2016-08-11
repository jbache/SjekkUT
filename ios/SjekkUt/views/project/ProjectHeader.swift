//
//  ProjectHeader.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 03/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import AlamofireImage

var kObservationContextImages = 0
var kObservationContextPlaces = 0

class ProjectHeader: UITableViewCell {

    var isObserving = false

    @IBOutlet weak var footerImage: UIImageView!
    @IBOutlet weak var projectImage: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var readMoreButton: UIButton!
    @IBOutlet weak var readMoreWidth: NSLayoutConstraint!
    @IBOutlet weak var readMoreSpacing: NSLayoutConstraint!
    @IBOutlet weak var nameLabel: UILabel!

    var project:Project? {
        didSet {
            stopObserving()
            nameLabel.text = project?.name
            let showReadMore:CGFloat = project?.infoUrl?.characters.count>0 ? 1.0 : 0.0
            readMoreButton.alpha = 1 * showReadMore
            readMoreWidth.constant = 100 * showReadMore
            readMoreSpacing.constant = 8 * showReadMore
            startObserving()
        }
    }

    deinit {
        stopObserving()
    }

    // MARK: private


    // MARK: actions

    @IBAction func joinChallengeClicked(sender: AnyObject) {
    }

    @IBAction func readMoreClicked(sender: AnyObject) {
    }

    // MARK: observing
    func startObserving() {
        if (!isObserving) {
            project?.addObserver(self, forKeyPath: "images", options: .Initial, context: &kObservationContextImages)
            project?.addObserver(self, forKeyPath: "places", options: .Initial, context: &kObservationContextPlaces)
            isObserving = true
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

        // update the header image view
        if (context == &kObservationContextImages) {
            switch project?.images?.count {
            case 2?:
                if let theImage = (project?.images?.objectAtIndex(1) as! DntImage?)!.url {
                    projectImage.af_setImageWithURL(NSURL(string:theImage)!)
                }
                fallthrough
            case 1?:
                if let theImage = (project?.images?.objectAtIndex(0) as! DntImage?)!.url {
                    footerImage.af_setImageWithURL(NSURL(string:theImage)!)
                }
            default:
                break
            }
        }
        else if(context == &kObserveProjectPlaces) {
            self.statusLabel.text = project?.progressDescription()
        }
    }

    func stopObserving() {
        if (isObserving) {
            project?.removeObserver(self, forKeyPath: "images")
            project?.removeObserver(self, forKeyPath: "places")
            isObserving = false
        }
    }
}