//
//  ProfileView.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 19/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import UIKit

class ProfileView: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var statsCollectionView: UICollectionView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var statHeaderView: UIView!

    var checkins: NSFetchedResultsController?
    var tempStatData = [
        ["name": "one", "value": "1/1"],
        ["name": "two", "value": "2/2"],
        ["name": "three", "value": "3"]
    ]
    
    @IBAction func logoutClicked(sender: AnyObject) {
        DntApi.instance.logout()
    }

    // MARK: view controller

    override func viewDidLoad() {
        userNameLabel.text = DntApi.instance.user?.fullName()
        checkins = getCheckins()
    }

    // MARK: collection data
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tempStatData.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let aStatisticCell = collectionView.dequeueReusableCellWithReuseIdentifier("StatisticCell", forIndexPath: indexPath) as! StatisticCell
        aStatisticCell.textLabel.text = tempStatData[indexPath.row]["name"]
        aStatisticCell.statLabel.text = tempStatData[indexPath.row]["value"]
        return aStatisticCell
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let aSize = CGSizeMake(collectionView.bounds.size.width/3, collectionView.bounds.size.width/3)
        return aSize
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }

    // MARK: table data

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (checkins!.sections?.count)!
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo:NSFetchedResultsSectionInfo = checkins!.sections![section] {
            return sectionInfo.numberOfObjects
        }
        return 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let aCheckinCell = tableView.dequeueReusableCellWithIdentifier("CheckinCell") as! CheckinCell
        let aCheckin = checkins?.objectAtIndexPath(indexPath)
        if let aPlace = aCheckin?.place {
            aCheckinCell.nameLabel.text = aPlace!.name
            aCheckinCell.dateLabel.text = aCheckin?.timeAgo()
        }
        return aCheckinCell
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Checkins", comment: "section header in checkin log")
    }

    func getCheckins() -> NSFetchedResultsController {
        let checkinsFetch = Checkin.fetch()
        checkinsFetch.sortDescriptors = [NSSortDescriptor(key:"date", ascending: false)]
        checkinsFetch.predicate = NSPredicate(format: "user == %@", argumentArray: [DntApi.instance.user!])
        
        let aCheckins = NSFetchedResultsController(fetchRequest: checkinsFetch, managedObjectContext: ModelController.instance().managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        aCheckins.delegate = self

        do {
            try aCheckins.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }

        return aCheckins
    }
}