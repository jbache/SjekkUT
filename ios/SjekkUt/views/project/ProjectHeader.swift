//
//  ProjectHeader.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 03/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

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
            nameLabel.text = project?.name
            stopObserving()
            readMoreButton.alpha = project?.infoUrl?.characters.count>0 ? 1.0 : 0.0
            startObserving()
        }
    }

    deinit {
        stopObserving()
    }

    // MARK: setup


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