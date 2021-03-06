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

// thanks to http://stackoverflow.com/a/37032476
public struct CoreImageFilter: ImageFilter {

    let filterName: String
    let parameters: [String: AnyObject]

    public init(filterName : String, parameters : [String : AnyObject]?) {
        self.filterName = filterName
        self.parameters = parameters ?? [:]
    }

    public var filter: UIImage -> UIImage {
        return { image in
            return image.af_imageWithAppliedCoreImageFilter(self.filterName, filterParameters: self.parameters) ?? image
        }
    }
}

class ProjectCell: UITableViewCell {

    var isObserving = false
    var kObservationContextImages = 0
    var kObservationContextPlaces = 0
    var kObservationContextName = 0
    var kObservationContextDistance = 0
    var kObservationContextGroups = 0

    @IBOutlet weak var backgroundContainer: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var foregroundImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var countyMunicipalityLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var groupLabel: UILabel!

    var backgroundImageRequest: Request?
    var foregroundImageRequest: Request?

    var backgroundImage: UIImage? = nil {
        didSet {
            backgroundImageView.image = backgroundImage
        }
    }

    var foregroundImage: UIImage? = nil {
        didSet {
            foregroundImageView.image = foregroundImage
        }
    }
    
    var project:Project? = nil {
        willSet {
            stopObserving()
        }
        didSet {
            setupProgressLabel()
            startObserving()
        }
    }

    deinit {
        stopObserving()
    }

    override func awakeFromNib() {
        setupShadowForLabel(nameLabel)
        setupShadowForLabel(progressLabel)
        setupShadowForLabel(distanceLabel)
        setupShadowForLabel(groupLabel)
    }

    func setupShadowForLabel(aLabel:UILabel) {
        aLabel.layer.shadowColor = UIColor.whiteColor().CGColor
        aLabel.layer.shadowOpacity = 1
        aLabel.layer.shadowRadius = 4
        aLabel.layer.shadowOffset = CGSizeZero
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupName()
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

    func setupProgressLabel() {
        if progressLabel != nil {
            progressLabel.text = project?.progressDescriptionShort()
        }
    }

    // MARK: background image

    func fetchBackgroundImage() {
        if let backgroundURL = project?.backgroundImageURLforSize(self.backgroundImageView!.bounds.size) {
            backgroundImageRequest = Alamofire.request(.GET,backgroundURL)
                .responseImage { response in
                    if let image = response.result.value {
                        self.backgroundImage =  image.af_imageAspectScaledToFillSize(self.bounds.size)
                    }
            }
        }
    }

    // MARK: foreground image 

    func fetchForegroundImage() {
        if let foregroundURL = project?.foregroundImageURLforSize(self.foregroundImageView.bounds.size) {
            foregroundImageRequest = Alamofire.request(.GET,foregroundURL)
                .responseImage { response in
                    if let image = response.result.value {
                        self.foregroundImage =  image.af_imageAspectScaledToFillSize(self.foregroundImageView.bounds.size)
                    }
            }
        }
    }

    // MARK: actions

    @IBAction func joinChallengeClicked(sender: AnyObject) {
    }

    @IBAction func readMoreClicked(sender: AnyObject) {
        if let aURL = project?.infoUrl?.URL() {
            UIApplication.sharedApplication().openURL(aURL)
        }
    }

    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animateWithDuration( 0.15 ) {
            self.backgroundImageView.alpha = highlighted ? 0.8 : 0.4;
        }
    }

    // MARK: observing
    func startObserving() {
        if (!isObserving && project != nil) {
            project?.addObserver(self, forKeyPath: "name", options: .Initial, context: &kObservationContextName)
            project?.addObserver(self, forKeyPath: "distance", options: .Initial, context: &kObservationContextDistance)
            project?.addObserver(self, forKeyPath: "images", options: .Initial, context: &kObservationContextImages)
            project?.addObserver(self, forKeyPath: "places", options: .Initial, context: &kObservationContextPlaces)
            project?.addObserver(self, forKeyPath: "groups", options: .Initial, context: &kObservationContextGroups)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(setupProgressLabel), name: kSjekkUtNotificationCheckinChanged, object: nil)
            isObserving = true
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

        // update the header image view
        if (context == &kObservationContextImages) {
            switch project?.images?.count {
            case 0?:
                backgroundImage = UIImage(named:"project-background-fallback")
                foregroundImage = UIImage(named:"project-foreground-fallback")
            case 1?:
                fetchBackgroundImage()
                foregroundImage = UIImage(named:"project-foreground-fallback")
            default:
                fetchBackgroundImage()
                fetchForegroundImage()
                break
            }
        }
        else if(context == &kObservationContextPlaces) {
            setupProgressLabel()
            self.countyMunicipalityLabel.text = project?.countyMunicipalityDescription()
        }
        else if(context == &kObservationContextName) {
            self.nameLabel.text = project?.name
        }
        else if(context == &kObservationContextDistance) {
            self.distanceLabel.text = project?.distanceDescription()
        }
        else if(context == &kObservationContextGroups) {
            if let aGroup:DntGroup = project?.groups?.firstObject as? DntGroup {
                self.groupLabel.text = aGroup.name
            }
            else {
                self.groupLabel.text = ""
            }
        }
    }

    func stopObserving() {
        if (isObserving) {
            project?.removeObserver(self, forKeyPath: "images")
            project?.removeObserver(self, forKeyPath: "places")
            project?.removeObserver(self, forKeyPath: "name")
            project?.removeObserver(self, forKeyPath: "distance")
            project?.removeObserver(self, forKeyPath: "groups")
            NSNotificationCenter.defaultCenter().removeObserver(self)
            isObserving = false
        }
        // cancel any in-flight network requests
        if backgroundImageRequest != nil {
            backgroundImageRequest!.cancel()
        }
        if foregroundImageRequest != nil {
            foregroundImageRequest?.cancel()
        }
    }
}