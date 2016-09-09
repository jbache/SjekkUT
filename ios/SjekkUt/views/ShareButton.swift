//
//  ShareButton.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 09/09/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

class ShareButton: UIButton {

    var checkin:Checkin? = nil

    convenience init(checkin aCheckin:Checkin) {
        self.init(frame:CGRectMake(0,0,44,33))
        checkin = aCheckin
        setup()
    }

    func setup() {
        titleLabel!.font = UIFont(name:"FontAwesome", size:25)
        setTitle("", forState: .Normal)
        addTarget(self, action: #selector(shareClicked), forControlEvents: .TouchUpInside)
    }

    func shareClicked(sender: AnyObject) {
        if checkin!.canShare {
            let currentController = UIApplication.sharedApplication().keyWindow?.rootViewController as UIViewController!
            let activityView:UIActivityViewController = UIActivityViewController(activityItems: [(checkin?.url?.URL())!], applicationActivities: nil)
            activityView.completionWithItemsHandler = { activity, success, items, error in
                currentController.dismissViewControllerAnimated(true, completion:nil)
            }
            currentController.presentViewController(activityView, animated: true, completion: nil)
        }
    }
}