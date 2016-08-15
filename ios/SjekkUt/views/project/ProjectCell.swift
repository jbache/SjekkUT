//
//  ProjectCell.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 03/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireImage

var kObservationContextImages = 0
var kObservationContextPlaces = 0
var kObservationContextName = 0
var kObservationContextDistance = 0

class ProjectCell: UITableViewCell {

    var isObserving = false

    @IBOutlet weak var projectImage: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var readMoreButton: UIButton!
    @IBOutlet weak var readMoreWidth: NSLayoutConstraint!
    @IBOutlet weak var readMoreSpacing: NSLayoutConstraint!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    var backgroundImageView: UIImageView?

    var backgroundImage: UIImage? {
        didSet {
            updateBackgroundImage()
        }
    }

    var foregroundImage: UIImage? {
        didSet {
            updateForegroundImage()
        }
    }

    
    var project:Project? = nil {
        didSet {
            stopObserving()

            setupReadMore()
            setupProgressLabel()
            setupBackgroundImage()

            startObserving()
        }
    }

    deinit {
        stopObserving()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupName()
    }

    override func prepareForReuse() {
        stopObserving()
        (self.backgroundView as! UIImageView).image = UIImage(named:"challenge-footer")
        self.projectImage.image = UIImage(named:"app-icon")
        self.nameLabel.text = ""
        self.distanceLabel.text = ""
        self.progressLabel.text = ""
    }

    // MARK: private

    func setupName() {
        nameLabel.text = project?.name
        let attributedText =
            NSAttributedString(string: (project?.name)!, attributes: [NSFontAttributeName: nameLabel.font]);
        let rect = attributedText.boundingRectWithSize(nameLabel.bounds.size, options: .UsesLineFragmentOrigin, context: nil)
        var aFrame = nameLabel.frame
        aFrame.size = rect.size
        nameLabel.frame = aFrame
    }

    func setupReadMore() {
        let showReadMore:CGFloat = project?.infoUrl?.characters.count>0 ? 1.0 : 0.0
        if (readMoreButton != nil) {
            readMoreButton.alpha = 1 * showReadMore
            readMoreWidth.constant = 100 * showReadMore
            readMoreSpacing.constant = 8 * showReadMore
        }
    }

    func setupProgressLabel() {
        if progressLabel != nil {
            progressLabel.text = project?.progressDescriptionShort()
        }
    }

    // MARK: background image

    func setupBackgroundImage() {
        var aBackgroundView = self.backgroundView as? UIImageView
        if self.backgroundView == nil {
            aBackgroundView = UIImageView(frame: self.bounds)
            aBackgroundView!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            aBackgroundView!.contentMode = .ScaleAspectFill
            aBackgroundView!.clipsToBounds = true
            aBackgroundView!.image = UIImage(named: "challenge-footer")
            self.backgroundView = aBackgroundView
            self.backgroundImageView = aBackgroundView
        }
    }

    func fetchBackgroundImage() {
        if let backgroundURL = project?.backgroundImageURLforSize(self.backgroundImageView!.bounds.size) {
            Alamofire.request(.GET,backgroundURL)
                .responseImage { response in
                    if let image = response.result.value {
                        self.backgroundImage =  image.af_imageAspectScaledToFillSize(self.bounds.size)
                    }
            }
        }
    }

    func updateBackgroundImage() {
        var theImage = UIImage(named: "challenge-footer")
        if backgroundImage != nil {
            theImage = backgroundImage
        }

        backgroundImageView?.image = theImage
    }

    // MARK: foreground image 

    func updateForegroundImage() {
        if foregroundImage == nil {
            projectImage.image = UIImage(named: "app-icon")
            return
        }
        else {
            projectImage.image = foregroundImage
        }
    }

    func fetchForegroundImage() {
        if let foregroundURL = project?.foregroundImageURLforSize(self.projectImage.bounds.size) {
            Alamofire.request(.GET,foregroundURL)
                .responseImage { response in
                    if let image = response.result.value {
                        self.foregroundImage =  image.af_imageAspectScaledToFillSize(self.projectImage.bounds.size)
                    }
            }
        }
    }

    // MARK: actions

    @IBAction func joinChallengeClicked(sender: AnyObject) {
    }

    @IBAction func readMoreClicked(sender: AnyObject) {
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateBackgroundImage()
        updateForegroundImage()
    }

    // MARK: observing
    func startObserving() {
        if (!isObserving) {
            project?.addObserver(self, forKeyPath: "name", options: .Initial, context: &kObservationContextName)
            project?.addObserver(self, forKeyPath: "distance", options: .Initial, context: &kObservationContextDistance)
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
                fetchForegroundImage()
                fallthrough
            case 1?:
                fetchBackgroundImage()
            default:
                break
            }
        }
        else if(context == &kObservationContextPlaces) {
            self.progressLabel.text = project?.progressDescriptionShort()
        }
        else if(context == &kObservationContextName) {
            self.nameLabel.text = project?.name
        }
        else if(context == &kObservationContextDistance) {
            self.distanceLabel.text = project?.distanceDescription()
        }
    }

    func stopObserving() {
        if (isObserving) {
            project?.removeObserver(self, forKeyPath: "images")
            project?.removeObserver(self, forKeyPath: "places")
            project?.removeObserver(self, forKeyPath: "name")
            project?.removeObserver(self, forKeyPath: "distance")
            isObserving = false
        }
    }
}