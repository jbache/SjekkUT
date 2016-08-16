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
var kObservationContextGroups = 0

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

    @IBOutlet weak var backgroundContainer: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var foregroundImageView: UIImageView!
    @IBOutlet weak var readMoreButton: UIButton!
    @IBOutlet weak var readMoreWidth: NSLayoutConstraint!
    @IBOutlet weak var readMoreSpacing: NSLayoutConstraint!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var groupLabel: UILabel!

    var backgroundImageRequest: Request?
    var foregroundImageRequest: Request?

    var backgroundImage: UIImage? = nil {
        didSet {
//            let filter = CIFilter(name: "CISepiaTone")
//            filter?.setValue(backgroundImage?.CIImage, forKey: kCIInputImageKey)
//            filter?.setValue(0.5, forKey: kCIInputIntensityKey)
//
//            if let output = filter?.valueForKey(kCIOutputImageKey) as? CIImage {
//                let filteredImage = UIImage(CIImage: output)
//                self.backgroundImageView.image = filteredImage
//            }
            backgroundImageView.image = backgroundImage
        }
    }

    var foregroundImage: UIImage? = nil {
        didSet {
            foregroundImageView.image = foregroundImage
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

    override func prepareForReuse() {
        stopObserving()
        backgroundImage = UIImage(named:"challenge-footer")
        foregroundImage = UIImage(named:"app-icon")
        nameLabel.text = ""
        distanceLabel.text = ""
        progressLabel.text = ""
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

    func hideReadMore() {
        readMoreSpacing.constant = 0
        readMoreWidth.constant = 0
        setNeedsLayout()
    }

    // MARK: background image

    func setupBackgroundImage() {
        if self.backgroundView == nil {
            self.backgroundView = backgroundContainer
        }
    }

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
            if project?.identifier == "57974036b565590001a98884" {
                print("foreground: \(foregroundURL)")
            }
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
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

//    override func setHighlighted(highlighted: Bool, animated: Bool) {
//        super.setHighlighted(highlighted, animated: animated)
//        updateBackgroundImage()
//        updateForegroundImage()
//    }

    // MARK: observing
    func startObserving() {
        if (!isObserving) {
            project?.addObserver(self, forKeyPath: "name", options: .Initial, context: &kObservationContextName)
            project?.addObserver(self, forKeyPath: "distance", options: .Initial, context: &kObservationContextDistance)
            project?.addObserver(self, forKeyPath: "images", options: .Initial, context: &kObservationContextImages)
            project?.addObserver(self, forKeyPath: "places", options: .Initial, context: &kObservationContextPlaces)
            project?.addObserver(self, forKeyPath: "groups", options: .Initial, context: &kObservationContextGroups)
            isObserving = true
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

        // update the header image view
        if (context == &kObservationContextImages) {
            switch project?.images?.count {
            case 0?:
                break
            case 1?:
                fetchBackgroundImage()
            default:
                fetchBackgroundImage()
                fetchForegroundImage()
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