//
//  ProjectListView.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 26/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

class ProjectListView: UITableViewController, NSFetchedResultsControllerDelegate {

    let turbasen = TurbasenApi.instance
    let dntApi = DntApi.instance
    var projects:NSFetchedResultsController?

    @IBOutlet weak var projectsTable: UITableView!

    // MARK: view controller
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        self.navigationItem.hidesBackButton = true

        dntApi.updateMemberDetailsOrFail {
            self.dntApi.logout()
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadTable), name: kSjekkUtNotificationCheckinChanged, object: nil)

        // only setup and load the table when core data is ready. in some cases this method will be hit before
        // core data has finished populating the database (e.g. in the case of migrations)
        ModelController.instance().delayUntilReady { 
            self.setupTable()
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let projectView = segue.destinationViewController as! PlaceListView
        projectView.project = sender as? Project
    }

    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        dntApi.logout()
    }

    // MARK: table data
    func setupTable() {

        // set up result controller
        projects = projectResults()

        // load data in table
        self.projectsTable.reloadData()

        // fetch any updated projects
        self.turbasen.getProjects()
    }

    func reloadTable() {
        self.projectsTable.reloadData()
    }

    func projectResults() -> NSFetchedResultsController {
        let aFetchRequest =  Project.fetchRequest()
        aFetchRequest.sortDescriptors = [NSSortDescriptor(key: "hasCheckins", ascending: false)]
        let someResults = NSFetchedResultsController(fetchRequest: aFetchRequest, managedObjectContext: ModelController.instance().managedObjectContext, sectionNameKeyPath: "hasCheckins", cacheName: nil)
        do {
            try someResults.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }

        someResults.delegate = self

        return someResults
    }

    // MARK: sections
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (projects?.sections?.count)!
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.projects?.sections![section].indexTitle == "1" ? NSLocalizedString("My projects", comment: "section header with checkins")
        :  NSLocalizedString("Other projects", comment: "section header without checkins")
    }

    // MARK: rows

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.projects?.sections![section].numberOfObjects)!
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let projectCell = tableView.dequeueReusableCellWithIdentifier("ProjectCell") as! ProjectCell
        return projectCell
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let project = self.projects?.objectAtIndexPath(indexPath) as! Project
        let projectCell = cell as! ProjectCell
        projectCell.project = project
    }

    // MARK: data changes
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.projectsTable.reloadData()
    }


    // MARK: table interaction
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let project = self.projects?.objectAtIndexPath(indexPath)
        self.performSegueWithIdentifier("showPlaces", sender: project)
    }
}