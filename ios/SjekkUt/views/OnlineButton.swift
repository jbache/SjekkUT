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

    let reachability = NetworkReachabilityManager(host: "www.dnt.no")

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        reachability?.listener = { status in
            switch status {
            case .Reachable:
                self.enabled = true
            default:
                self.enabled = false
            }
        }
        reachability?.startListening()
        enabled = (reachability?.isReachable)!
    }

    deinit {
        reachability?.stopListening()
    }
}