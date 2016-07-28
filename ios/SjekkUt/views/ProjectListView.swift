//
//  ProjectListView.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 26/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

class ProjectListView: UITableViewController, NSFetchedResultsControllerDelegate {

    let turbasen:TurbasenApi
    var projects:NSFetchedResultsController?

    @IBOutlet weak var projectsTable: UITableView!

    // MARK: view controller
    required init?(coder aDecoder: NSCoder) {
        turbasen = TurbasenApi()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        // delay table setup if Core Data isn't finished loading
        if (ModelController.instance().managedObjectContext == nil) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(setupTable), name: SjekkUtDatabaseModelReadyNotification, object: nil)
        }
        else {
            self.setupTable()
        }

        self.navigationItem.hidesBackButton = true
    }

    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        let aProject:Project = Project.insertTemporary() as! Project
        aProject.name = "hello"
        ModelController.instance().save()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let projectView = segue.destinationViewController as! PlaceListView
        projectView.project = sender as? Project
    }


    // MARK: table data
    func setupTable() {
        
        // set up datasource
        projects = projectResults()
        projects?.delegate = self

        // load data in table
        self.projectsTable.reloadData()

        // fetch any updated projects
        self.turbasen.getProjects()
    }

    func projectResults() -> NSFetchedResultsController {
        let aFetchRequest =  Project.fetchRequest()
        let someResults = NSFetchedResultsController(fetchRequest: aFetchRequest, managedObjectContext: ModelController.instance().managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try someResults.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }

        return someResults
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.projects == nil) {
            return 0
        }
        return (self.projects?.fetchedObjects?.count)!
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let project = self.projects?.objectAtIndexPath(indexPath) as! Project
        let projectCell = tableView.dequeueReusableCellWithIdentifier("ProjectCell") as! ProjectCell
        projectCell.project = project
        return projectCell
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