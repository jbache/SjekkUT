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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reloadTable), name: kSjekkUtNotificationCheckinChanged, object: nil)
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
        self.projectsTable.contentOffset = CGPointMake(0, searchController.searchBar.frame.size.height)
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
        let projectView = segue.destinationViewController as! PlaceListView
        projectView.project = sender as? Project
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

            // load data in table
            self.reloadTable()

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
        projectCell.hideReadMore()
        projectCell.project = project
    }

    // MARK: data changes
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        reloadTable()
    }

    // MARK: table interaction
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let project = self.projects?.objectAtIndexPath(indexPath)
        self.performSegueWithIdentifier("showPlaces", sender: project)
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 106
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