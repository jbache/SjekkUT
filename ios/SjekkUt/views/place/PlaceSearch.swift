//
//  PlaceSearch.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 04/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

class PlaceSearch: UIViewController {

    var place:Place! = nil
    @IBOutlet weak var checkinLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: view controller

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        popViewControllerIfTimeout()
        activityIndicator.startAnimating()
        self.checkinLabel.text = NSLocalizedString("Checking in...", comment: "Checking in label in summit search")
        SjekkUtApi.instance.doPlaceCheckin(self.place) {
            result in
            self.activityIndicator.stopAnimating()
            switch result {
            case .Success:
                self.performSegueWithIdentifier("showPlace", sender: self.place)
            case .Failure(let error):
                print("failed to visit \(self.place.name): \(error)")
                self.performSegueWithIdentifier("showPlace", sender: self.place)
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