//
//  JoinProjectCell.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 29/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation

func getImageWithColor(color: UIColor, size: CGSize) -> UIImage {
    let rect = CGRectMake(0, 0, size.width, size.height)
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    color.setFill()
    UIRectFill(rect)
    let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

class JoinProjectCell: UITableViewCell {

    var isObserving:Bool = false
    var kObservingParticipation = 0

    var project:Project? = nil {
        didSet {
            stopObserving()
            joinLeaveButton.setBackgroundImage(getImageWithColor(UIColor.grayColor(), size: joinLeaveButton.bounds.size), forState: .Disabled)
            joinLeaveButton.setTitle(NSLocalizedString("Working..", comment: "join/leave in progress"), forState: .Disabled)
            joinLeaveButton.setTitleColor(UIColor.whiteColor(), forState: .Disabled)
            startObserving()
        }
    }

    deinit {
        stopObserving()
    }

    @IBOutlet var joinLeaveButton: UIButton!
    @IBOutlet var joinLeaveLabel: UILabel!

    @IBAction func joinProjectClicked(sender: AnyObject) {

        joinLeaveButton.enabled = false

        if project!.isParticipating!.boolValue {
            SjekkUtApi.instance.doLeaveProject(project!) {
                self.joinLeaveButton.enabled = true
            }
        }
        else {
            SjekkUtApi.instance.doJoinProject(project!) {
                self.joinLeaveButton.enabled = true
            }
        }
    }


    func startObserving() {
        if !isObserving {
            project?.addObserver(self, forKeyPath: "isParticipating", options: .Initial, context: &kObservingParticipation)
            isObserving = true
        }
    }

    func stopObserving() {
        if isObserving {
            project?.removeObserver(self, forKeyPath: "isParticipating")
            isObserving = false
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        switch(keyPath!, context) {
        case("isParticipating", &kObservingParticipation):
            UIView.animateWithDuration(kSjekkUtConstantAnimationDuration, animations: { 
                self.updateTitles()
            })
        default:
            break
        }
    }

    func updateTitles() {
        if self.project!.isParticipating!.boolValue {
            self.joinLeaveButton.setTitle(NSLocalizedString("Leave", comment: "Leave project button"), forState: .Normal)
            self.joinLeaveLabel.text = NSLocalizedString("Leave project", comment: "Leave project label")
        }
        else {
            self.joinLeaveButton.setTitle(NSLocalizedString("Join", comment: "Leave project button"), forState: .Normal)
            self.joinLeaveLabel.text = NSLocalizedString("Join project to track progress", comment: "Leave project label")
        }
    }
}