//
//  PlaceSearch.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 04/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

class PlaceSearch: UIViewController {

    var project:Project? = nil
    @IBOutlet weak var checkinLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: view controller

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        popViewControllerIfTimeout()
        activityIndicator.startAnimating()
        Location.instance().getSingleUpdate { (location:CLLocation!) in
            self.activityIndicator.stopAnimating()
            self.checkinLabel.text = NSLocalizedString("Checking in...", comment: "Checking in label in summit search")
            let aPlace = self.project!.findNearest()
            SjekkUtApi.instance.doPlaceVisit(aPlace) {
                result in
                switch result {
                case .Success:
                    self.performSegueWithIdentifier("showPlace", sender: aPlace)
                case .Failure(let error):
                    self.performSegueWithIdentifier("showPlace", sender: error)
                }
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let placeView = segue.destinationViewController as! PlaceView
        if segue.identifier == "showPlace" {
            if let aPlace = sender as? Place {
                placeView.place = aPlace
            }
            else if let aCheckin = sender as? Checkin {
                placeView.checkin = aCheckin
            }
        }

    }

    override func viewDidDisappear(animated: Bool) {
        var viewControllers = self.navigationController?.viewControllers
        viewControllers?.removeAtIndex((viewControllers?.indexOf(self))!)
        self.navigationController?.viewControllers = viewControllers!
        super.viewDidDisappear(animated)
    }

    // MARK: private

    func popViewControllerIfTimeout() {
        delay(30) {
            if self.navigationController?.topViewController == self {
                self.navigationController?.popViewControllerAnimated(true)
                NSNotificationCenter.defaultCenter().postNotificationName(SjekkUtTimeoutNotification, object: nil)
            }
        }
    }
}