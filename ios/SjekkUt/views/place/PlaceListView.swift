//
//  PlaceListView.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 26/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import HockeySDK

var kObserveProjectPlaces = 0
var kObserveLocation = 0

class PlaceListView: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {

    let turbasen = TurbasenApi.instance
    var project:Project? = nil
    var places:NSFetchedResultsController? = nil
    var projectHeader:ProjectCell? = nil

    @IBOutlet weak var placesTable: UITableView!
    @IBOutlet weak var checkinButton: UIButton!
    @IBOutlet weak var feedbackButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!

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

        // set a header on the table
        projectHeader = self.placesTable.dequeueReusableCellWithIdentifier("ProjectCell") as? ProjectCell
        projectHeader!.project = self.project
        self.placesTable.tableHeaderView = projectHeader
    }

    func updateData() {
        turbasen.getProjectAndPlaces(self.project!)
        Location.instance().getSingleUpdate(nil)
    }

// MARK: view controller

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.startObserving()
        self.updateData()
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
        Location.instance().addObserver(self, forKeyPath: "currentLocation", options: .Initial, context: &kObserveLocation)
    }

    func stopObserving() {
        Location.instance().removeObserver(self, forKeyPath: "currentLocation")
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (context == &kObserveLocation && Location.instance().currentLocation != nil) {
            project!.updateDistance()
            project!.updatePlacesDistance()
        }
    }

    // MARK: table sections

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (places?.sections?.count)!
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return project?.progressDescriptionLong()
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
        return 80
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