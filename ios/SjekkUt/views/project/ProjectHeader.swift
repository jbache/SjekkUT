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

class ProjectHeader: UITableViewCell {

    var isObserving = false

    @IBOutlet weak var footerImage: UIImageView!
    @IBOutlet weak var projectImage: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var readMoreButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!

    var project:Project? {
        didSet {
            stopObserving()
            nameLabel.text = project?.name
            readMoreButton.alpha = project?.infoUrl?.characters.count>0 ? 1.0 : 0.0
            statusLabel.text = projectProgress()
            joinButton.alpha = 0
            startObserving()
        }
    }

    deinit {
        stopObserving()
    }

    // MARK: private

    func projectProgress() -> String {

        let checkinsPredicate = NSPredicate(format: "checkins.@count > 0")
        let checkins = project?.places?.filteredOrderedSetUsingPredicate(checkinsPredicate)

        return NSLocalizedString("You have summited \(checkins!.count) of \((project?.places?.count)!) so far!", comment:"count summits in challenge")
    }


    // MARK: actions

    @IBAction func joinChallengeClicked(sender: AnyObject) {
    }

    @IBAction func readMoreClicked(sender: AnyObject) {
    }

    // MARK: observing
    func startObserving() {
        if (!isObserving) {
            project?.addObserver(self, forKeyPath: "images", options: .Initial, context: &kObservationContextImages)
            isObserving = true
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

        // update the header image view
        if (context == &kObservationContextImages) {
            switch project?.images?.count {
            case 2?:
                if let theImage = project?.images?.objectAtIndex(1) as! DntImage? {
                    projectImage.af_setImageWithURL(NSURL(string:theImage.url!)!)
                }
                fallthrough
            case 1?:
                if let theImage = project?.images?.objectAtIndex(0) as! DntImage? {
                    footerImage.af_setImageWithURL(NSURL(string:theImage.url!)!)
                }
            default:
                break
            }
        }
    }

    func stopObserving() {
        if (isObserving) {
            project?.removeObserver(self, forKeyPath: "images")
            isObserving = false
        }
    }
}