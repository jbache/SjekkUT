//
//  PlaceListView.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 26/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import HockeySDK
import Alamofire

// TODO: properly reuse the header as a reusable table cell

class PlaceListView: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {

    let turbasen = TurbasenApi.instance
    var project:Project? = nil
    var places:NSFetchedResultsController? = nil
    var vJoinProjectHeight:Float = 50
    var vLeaveProjectHeight:Float = 0

    var isObserving = false
    var kObserveLocation = 0
    var kObserveParticipation = 0
    var kObservationContextImages = 0
    var kObservationContextPlaces = 0
    var kObservationContextName = 0
    var kObservationContextDistance = 0
    var kObservationContextGroups = 0

    @IBOutlet var placesTable: UITableView!
    @IBOutlet var checkinButton: UIButton!
    @IBOutlet var feedbackButton: UIButton!
    @IBOutlet var countyMunicipalityLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var groupLabel: UILabel!
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var readMoreButton: UIButton!
    @IBOutlet var readMoreSpacing: NSLayoutConstraint!
    @IBOutlet var readMoreWidth: NSLayoutConstraint!

    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var foregroundImageView: UIImageView!

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

    override func viewDidLoad() {
        setupCheckinButton()
        setupTable()
    }

    // MARK: private

    func setupCheckinButton() {
        self.checkinButton.titleLabel?.lineBreakMode = .ByWordWrapping
        self.checkinButton.titleLabel?.numberOfLines = 2
        self.checkinButton.titleLabel?.textAlignment = .Center
    }

    @IBAction func feedbackClicked(sender: AnyObject) {
        let hockeyManager = BITHockeyManager.sharedHockeyManager()
        let feedbackList = hockeyManager.feedbackManager.feedbackListViewController(false)
        self.navigationController!.pushViewController(feedbackList, animated:true)
    }

    @IBAction func readMoreClicked(sender: AnyObject) {
        if let aURL = project?.infoUrl?.URL() {
            UIApplication.sharedApplication().openURL(aURL)
        }
    }

    func setupTable() {
        let placesFetch = Place.fetchRequest()
        placesFetch.predicate = NSPredicate(format: "%@ IN projects", self.project!)
        placesFetch.sortDescriptors = [ NSSortDescriptor.init(key: "distance", ascending: true) ]
        self.places = NSFetchedResultsController(fetchRequest: placesFetch, managedObjectContext: ModelController.instance().managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        self.places?.delegate = self
        do {
            try self.places!.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }

    func updateData() {
        turbasen.getProjectAndPlaces(project!)
        Location.instance().getSingleUpdate { location in
            self.project!.updateDistance()
            let sortedPlaces = self.project!.places!.sortedArrayUsingDescriptors( [NSSortDescriptor(key: "distance", ascending: true)] ) as! [Place]
            if let firstPlace = sortedPlaces.first {
                self.checkinButton.titleLabel!.numberOfLines = 3
                self.checkinButton.setTitle( NSLocalizedString("Check in to \(firstPlace.name!)",comment:"check in button title"), forState:.Normal)
                UIView.animateWithDuration(kSjekkUtConstantAnimationDuration) {
                    self.checkinButton.alpha = CGFloat( firstPlace.canCheckIn() )
                }
            }

        }
    }

    // MARK: view controller

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        checkinButton.alpha = 0
        startObserving()
        setupReadMore()
        updateData()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopObserving()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPlace" {
            let placeView = segue.destinationViewController as! PlaceView
            placeView.place = sender as? Place
        }
        else if segue.identifier == "startSearch" {
            let searchView = segue.destinationViewController as! PlaceSearch
            searchView.project = self.project! as Project
        }
    }

    // MARK: observing

    func startObserving() {
        if (!isObserving ) {
            if project != nil {
                project?.addObserver(self, forKeyPath: "name", options: .Initial, context: &kObservationContextName)
                project?.addObserver(self, forKeyPath: "distance", options: .Initial, context: &kObservationContextDistance)
                project?.addObserver(self, forKeyPath: "images", options: .Initial, context: &kObservationContextImages)
                project?.addObserver(self, forKeyPath: "places", options: .Initial, context: &kObservationContextPlaces)
                project?.addObserver(self, forKeyPath: "groups", options: .Initial, context: &kObservationContextGroups)
            }
            Location.instance().addObserver(self, forKeyPath: "currentLocation", options: .Initial, context: &kObserveLocation)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(setupProgressLabel), name: kSjekkUtNotificationCheckinChanged, object: nil)
            isObserving = true
        }
    }

    func stopObserving() {
        if (isObserving) {
            project?.removeObserver(self, forKeyPath: "images")
            project?.removeObserver(self, forKeyPath: "places")
            project?.removeObserver(self, forKeyPath: "name")
            project?.removeObserver(self, forKeyPath: "distance")
            project?.removeObserver(self, forKeyPath: "groups")
            Location.instance().removeObserver(self, forKeyPath: "currentLocation")
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

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        switch context  {
        case &kObserveLocation:
            if Location.instance().currentLocation != nil {
                project!.updateDistance()
                project!.updatePlacesDistance()
            }
        case &kObservationContextImages:
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
        case &kObservationContextPlaces:
            setupProgressLabel()
            self.countyMunicipalityLabel.text = project?.countyMunicipalityDescription()
        case &kObservationContextName:
            self.nameLabel.text = project?.name
        case &kObservationContextDistance:
            self.distanceLabel.text = project?.distanceDescription()
        case &kObservationContextGroups:
            if let aGroup:DntGroup = project?.groups?.firstObject as? DntGroup {
                self.groupLabel.text = aGroup.name
            }
            else {
                self.groupLabel.text = ""
            }
        default:
            break
        }
    }

    func setupProgressLabel() {
        if progressLabel != nil {
            progressLabel.text = project?.progressDescriptionShort()
        }
    }

    func setupReadMore() {
        let showReadMore:CGFloat = project?.infoUrl?.characters.count>0 ? 1.0 : 0.0
        if (readMoreButton != nil) {
            readMoreButton.alpha = 1 * showReadMore
            readMoreWidth.constant = 33 * showReadMore
            readMoreSpacing.constant = 8 * showReadMore
        }
    }

    func fetchBackgroundImage() {
        if let backgroundURL = project?.backgroundImageURLforSize(self.backgroundImageView!.bounds.size) {
            backgroundImageRequest = Alamofire.request(.GET,backgroundURL)
                .responseImage { response in
                    if let image = response.result.value {
                        self.backgroundImage =  image.af_imageAspectScaledToFillSize(self.backgroundImageView.bounds.size)
                    }
            }
        }
    }

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

    // MARK: sections

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (places?.sections?.count)!
    }

    func tableView(tableView:UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let aJoinProjectCell = tableView.dequeueReusableCellWithIdentifier("JoinProjectCell") as! JoinProjectCell
        aJoinProjectCell.project = project
        return aJoinProjectCell
    }

    func tableView(tableView:UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(vJoinProjectHeight)
    }

    // MARK: table rows

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (places?.sections![section].numberOfObjects)!
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let aPlaceCell = tableView.dequeueReusableCellWithIdentifier("PlaceCell") as! PlaceCell
        return aPlaceCell
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let aPlace = self.places?.objectAtIndexPath(indexPath) as! Place
        let aPlaceCell = cell as! PlaceCell
        aPlaceCell.place = aPlace
    }

    // MARK: table interaction

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 96
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let aPlace = self.places?.objectAtIndexPath(indexPath)
        self.performSegueWithIdentifier("showPlace", sender: aPlace)
    }

    // MARK: fetched results controller

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.placesTable.reloadData()
    }
}