//
//  PlaceListView.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 26/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

var kObserveProjectPlaces = 0

class PlaceListView: UIViewController, UITableViewDelegate, UITableViewDataSource {

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
        turbasen?.getProjectAndPlaces(self.project!.identifier!)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.project!.addObserver(self, forKeyPath: "places", options: .Initial, context: &kObserveProjectPlaces)
    }

    override func viewWillDisappear(animated: Bool) {
        self.project!.removeObserver(self, forKeyPath: "places", context: &kObserveProjectPlaces)
    }

    // MARK: table data
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (context == &kObserveProjectPlaces) {
            self.placesTable.reloadData()
        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.project!.places!.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let aPlace = self.project!.places!.objectAtIndex(indexPath.row) as! Place
        let aPlaceCell = tableView.dequeueReusableCellWithIdentifier("PlaceCell") as! PlaceCell
        aPlaceCell.place = aPlace
        return aPlaceCell
    }

    // MARK: table interaction


}