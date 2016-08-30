//
//  ProfileView.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 19/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import UIKit

class ProfileView: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {

    var isObserving = false
    var kObserveUserName = 0
    var kObserveUserPublicCheckins = 0

    let dntUser = DntApi.instance.user

    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var statsCollectionView: UICollectionView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var statHeaderView: UIView!
    @IBOutlet var publicCheckinsSwitch: UISwitch!

    var checkins:[[String:AnyObject]] = [[String:AnyObject]]()
    var tempStatData = [
        ["name": "one", "value": "1/1"],
        ["name": "two", "value": "2/2"],
        ["name": "three", "value": "3"]
    ]
    
    @IBAction func logoutClicked(sender: AnyObject) {
        DntApi.instance.logout()
    }

    @IBAction func publicCheckinChanged(sender: AnyObject) {
        SjekkUtApi.instance.doChangePublicCheckin(publicCheckinsSwitch.on) {

        }
    }

    // MARK: view controller

    override func viewDidLoad() {
        checkins = getCheckins()
    }

    override func viewWillAppear(animated: Bool) {
        startObserving()
    }

    override func viewWillDisappear(animated: Bool) {
        stopObserving()
    }

    func startObserving() {
        if (!isObserving) {
            dntUser?.addObserver(self, forKeyPath: "firstName", options: .Initial, context: &kObserveUserName)
            dntUser?.addObserver(self, forKeyPath: "publicCheckins", options: .Initial, context: &kObserveUserPublicCheckins)
            isObserving = true
        }
    }

    func stopObserving() {
        if (isObserving) {
            dntUser?.removeObserver(self, forKeyPath: "firstName")
            dntUser?.removeObserver(self, forKeyPath: "publicCheckins")
            isObserving = false
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        switch(keyPath!, context) {
        case ("firstName", &kObserveUserName):
            userNameLabel.text = dntUser?.fullName()
        case("publicCheckins", &kObserveUserPublicCheckins):
            publicCheckinsSwitch.setOn((dntUser?.publicCheckins?.boolValue)!, animated: true)
        default:
            break
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let placeView = segue.destinationViewController as! PlaceView
        if let aPlace:Place = ((sender as! CheckinCell).place)! as Place {
            placeView.place = aPlace
        }
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

    // MARK: table interaction

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }

    // MARK: table sections

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let aHeader = tableView.dequeueReusableCellWithIdentifier("CheckinHeaderCell") as! CheckinHeaderCell
        return aHeader
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 69
    }

    // MARK: table rows

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return checkins.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let aCheckinCell = tableView.dequeueReusableCellWithIdentifier("CheckinCell") as! CheckinCell
        return aCheckinCell
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let aCheckinCell = cell as! CheckinCell
        let checkinCount = checkins[indexPath.row]["count"]
        let aPlaceId = checkins[indexPath.row]["place.identifier"]
        let aPlace = Place.findWithId(aPlaceId!)
        aCheckinCell.place = aPlace
        aCheckinCell.dateLabel.text = "\(checkinCount!)"
    }

    func getCheckins() -> [[String:AnyObject]] {
        let checkinsFetch = Checkin.fetch()
        checkinsFetch.predicate = NSPredicate(format: "user == %@", argumentArray: [DntApi.instance.user!])

        let placeDesc:NSRelationshipDescription = checkinsFetch.entity!.relationshipsByName["place"]!;
        let keyPathExpression:NSExpression = NSExpression(forKeyPath:"identifier") // Does not really matter
        let countExpression:NSExpression = NSExpression(forFunction:"count:", arguments: [keyPathExpression])

        let expressionDescription:NSExpressionDescription = NSExpressionDescription()
        expressionDescription.name = "count"
        expressionDescription.expression = countExpression
        expressionDescription.expressionResultType = .Integer32AttributeType

        checkinsFetch.propertiesToFetch = [placeDesc, "place.name", "place.identifier", expressionDescription];
        checkinsFetch.propertiesToGroupBy = ["place", "place.name", "place.identifier"];
        checkinsFetch.resultType = .DictionaryResultType

        var aResult = [[String:AnyObject]]()
        do {
            aResult = try ModelController.instance().managedObjectContext.executeFetchRequest(checkinsFetch) as! [[String:AnyObject]]
            return aResult.sort {item1, item2 in
                let count1 = item1["count"] as! Int
                let count2 = item2["count"] as! Int
                return count1 > count2
            }
        } catch {
            fatalError("Failed to fetch: \(error)")
        }

        return aResult
    }
}