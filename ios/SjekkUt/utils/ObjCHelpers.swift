//
//  ObjCHelpers.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 17/08/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import AlamofireNetworkActivityIndicator

public class SwiftHelper : NSObject {

    static func initNetworkIndicator()  {
        NetworkActivityIndicatorManager.sharedManager.isEnabled = true
    }
}