//
//  FeedbackButton.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 31/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import HockeySDK

@IBDesignable
class FeedbackButton: UIButton {
    override func awakeFromNib() {
        titleLabel!.font = UIFont(name: "FontAwesome", size: 25)!
        setTitle("", forState: .Normal)
        addTarget(self, action: #selector(feedbackClicked), forControlEvents: .TouchUpInside)
    }

    func feedbackClicked(sender: AnyObject) {
        let hockeyManager = BITHockeyManager.sharedHockeyManager()
        let feedbackList = hockeyManager.feedbackManager.feedbackListViewController(false)
        let aNavigationController = UIApplication.sharedApplication().keyWindow?.rootViewController as! UINavigationController
        aNavigationController.pushViewController(feedbackList, animated:true)
    }
}