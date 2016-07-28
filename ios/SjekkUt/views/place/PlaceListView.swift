//
//  PlaceListView.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 26/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

var kObserveProjectPlaces = 0
var kObserveLocation = 0

class PlaceListView: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {

    let turbasen:TurbasenApi?
    var project:Project? = nil
    var places:NSFetchedResultsController? = nil

    @IBOutlet weak var placesTable: UITableView!
    @IBOutlet weak var checkinButton: UIButton!
    @IBOutlet weak var feedbackButton: UIButton!
    @IBOutlet weak var infoButton: UIButton!

    required init?(coder aDecoder: NSCoder) {
        turbasen = TurbasenApi()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        self.setupCheckinButton()
        self.setupTable()
    }

// MARK: private

    func setupCheckinButton() {
        self.checkinButton.titleLabel?.lineBreakMode = .ByWordWrapping
        self.checkinButton.titleLabel?.numberOfLines = 2
        self.checkinButton.titleLabel?.textAlignment = .Center
    }

    func setupTable() {
        let placesFetch = Place.fetchRequest()
        placesFetch.predicate = NSPredicate(format: "%@ IN projects", self.project!)
        placesFetch.sortDescriptors = [ NSSortDescriptor.init(key: "distance", ascending: true) ]
        self.places = NSFetchedResultsController(fetchRequest: placesFetch, managedObjectContext: ModelController.instance().managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try self.places!.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }

    func updateData() {
        turbasen?.getProjectAndPlaces(self.project!.identifier!)
        Location.instance().getSingleUpdate(nil)
    }

    func didCheckInTo(notification:NSNotification) {
        let aCheckin = notification.object as Checkin
        let aPlace = aCheckin.place as Place
        let checkinText = String(format:NSLocalizedString("Yay! Checked in to %@", comment: "check in notification text"), place.name
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
        if (segue.identifier == "showPlace") {
            let placeView = segue.destinationViewController as! SummitView
            placeView.place = sender as! Place
        }
    }

// MARK: observing

    func startObserving() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didCheckInTo), name: SjekkUtCheckedInNotification, object: nil)
        Location.instance().addObserver(self, forKeyPath: "currentLocation", options: .Initial, context: &kObserveLocation)
    }

    func stopObserving() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        Location.instance().removeObserver(self, forKeyPath: "currentLocation")
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (context == &kObserveLocation && Location.instance().currentLocation != nil) {
            self.project!.updateDistance()
        }
    }

// MARK: table data

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.places?.fetchedObjects?.count)!
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let aPlace = self.places?.objectAtIndexPath(indexPath) as! Place
        let aPlaceCell = tableView.dequeueReusableCellWithIdentifier("PlaceCell") as! PlaceCell
        aPlaceCell.place = aPlace
        return aPlaceCell
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.placesTable.reloadData()
    }

// MARK: table interaction

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var aPlace = self.places?.objectAtIndexPath(indexPath)
        self.performSegueWithIdentifier("showPlace", sender: aPlace)
    }

}