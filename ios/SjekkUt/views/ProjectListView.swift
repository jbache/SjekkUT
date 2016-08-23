//
//  ProjectListView.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 26/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

class ProjectListView: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating {

    let turbasen = TurbasenApi.instance
    let dntApi = DntApi.instance
    var projects:NSFetchedResultsController?
    let searchController = UISearchController(searchResultsController:nil)

    @IBOutlet weak var projectsTable: UITableView!
    @IBOutlet weak var profileButton: UIButton!

    // MARK: view controller
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        self.navigationItem.hidesBackButton = true
        

        // update the table (and project progress) when checkins arrive
        self.refreshControl!.addTarget(self, action:#selector(refreshProjects), forControlEvents:.ValueChanged)

        // attempt to call member details, while verifying the current authorization token
        dntApi.updateMemberDetailsOrFail {
            self.dntApi.logout()
        }

        setupTable()
        setupSearchResults()
    }

    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        if (projects == nil) {
            projects = self.projectResults()
            reloadTable()
        }
        projectsTable.contentOffset = CGPointMake(0, searchController.searchBar.frame.size.height)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        Location.instance().getSingleUpdate { location in
            for project:Project in self.projects?.fetchedObjects! as! [Project] {
                project.updateDistance()
            }
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.active = false
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPlaces" {
            let projectView = segue.destinationViewController as! PlaceListView
            projectView.project = sender as? Project
        }
    }

    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        #if DEBUG
            dntApi.logout()
        #endif
    }

    // MARK: table data

    func setupTable() {

        // only setup and load the table when core data is ready. in some cases this method will be hit before
        // core data has finished populating the database (e.g. in the case of migrations)
        ModelController.instance().delayUntilReady {

            // set up result controller
            self.projects = self.projectResults()

            // fetch any updated projects
            self.turbasen.getProjects()
        }
    }

    func reloadTable() {
        self.projectsTable.reloadData()
    }

    func projectResults() -> NSFetchedResultsController {
        let aFetchRequest =  Project.fetchRequest()
        aFetchRequest.sortDescriptors = [NSSortDescriptor(key: "hasCheckins", ascending: false), NSSortDescriptor(key: "distance", ascending: true)]
        aFetchRequest.includesPendingChanges = false
        let someResults = NSFetchedResultsController(fetchRequest: aFetchRequest, managedObjectContext: ModelController.instance().managedObjectContext, sectionNameKeyPath: "hasCheckins", cacheName: nil)
        do {
            try someResults.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }

        someResults.delegate = self

        return someResults
    }

    func refreshProjects() {
        turbasen.getProjectsAnd {
            self.refreshControl!.endRefreshing()
        }
    }

    // MARK: sections
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return (projects?.sections?.count)!
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (searchController.active && searchController.searchBar.text!.characters.count > 0) {
            return NSLocalizedString("Search results", comment: "project header when searching")
        }
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
        if let projectCell = cell as? ProjectCell {
            configureCell(projectCell, forRowAtIndexPath:indexPath)
            projectCell.hideReadMore()
        }
    }

    func configureCell(aCell:ProjectCell, forRowAtIndexPath anIndexPath:NSIndexPath) {
        if let project:Project = self.projects?.objectAtIndexPath(anIndexPath) as? Project {
            aCell.project = project
        }
    }

    // MARK: data changes

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.projectsTable.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)
    {
        let aTable:UITableView = self.projectsTable
        switch type {
        case .Insert:
            aTable.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation:.Fade)
        case .Delete:
            aTable.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation:.Fade)
        default:
            break
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        switch type {
        case NSFetchedResultsChangeType(rawValue: 0)!:
            // iOS 8 bug - Do nothing if we get an invalid change type.
            break;
        case .Insert:
            projectsTable.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation:.Fade)
        case .Delete:
            projectsTable.deleteRowsAtIndexPaths([indexPath!], withRowAnimation:.Fade)
        case .Update:
            if let aCell = projectsTable.cellForRowAtIndexPath(indexPath!) as? ProjectCell {
                configureCell(aCell, forRowAtIndexPath: indexPath!)
            }
        case .Move:
            projectsTable.deleteRowsAtIndexPaths([indexPath!], withRowAnimation:.Fade)
            projectsTable.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation:.Fade)
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        projectsTable.endUpdates()
    }

    // MARK: table interaction
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let project = projects?.objectAtIndexPath(indexPath)
        performSegueWithIdentifier("showPlaces", sender: project)
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 110
    }

    // MARK: seraching
    func setupSearchResults() {
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        self.tableView.tableHeaderView = searchController.searchBar
    }

    func updateSearchResultsForSearchController(searchController:UISearchController) {
        if !searchController.active || searchController.searchBar.text!.characters.count == 0 {
            projects!.fetchRequest.predicate = nil
        }
        else if let aSearchTerm:String = searchController.searchBar.text {
            projects!.fetchRequest.predicate = NSPredicate(format: "name contains[cd] %@ OR SUBQUERY(places, $place, $place.name contains[cd] %@).@count > 0", aSearchTerm, aSearchTerm)
        }

        do {
            try projects!.performFetch()
            projectsTable.reloadData()
        } catch {
            fatalError("Failed to fetch after updating predicate: \(error)")
        }
    }
}