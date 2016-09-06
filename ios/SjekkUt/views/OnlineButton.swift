//
//  OnlineButton.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 06/09/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import Alamofire

class OnlineButton: UIButton {

    let reachability = NetworkReachabilityManager(host: "sjekkut.app.dnt.no")

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setBackgroundImage(UIColor.grayColor().imageWithSize(self.bounds.size), forState: .Disabled)
        reachability?.listener = { status in
            switch status {
            case .Reachable:
                self.enabled = true
            default:
                self.enabled = false
            }
        }
        enabled = (reachability?.isReachable)!
        reachability?.startListening()
    }

    deinit {
        reachability?.stopListening()
    }
}