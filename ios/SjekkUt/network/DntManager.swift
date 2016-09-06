//
//  DntManager.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 01/09/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import Alamofire
import CFNetwork

public class DntManager: Alamofire.Manager {
    
    override public func request(URLRequest: URLRequestConvertible) -> Request {
        // force using cache when offline
        if (DntApi.instance.isOffline) {
            URLRequest.URLRequest.cachePolicy = .ReturnCacheDataDontLoad
            print("offline request: \(URLRequest.URLRequest.URLString)")
        }
        return super.request(URLRequest)
    }

    func failHandler(error:NSError?) {
        switch (error?.domain, error?.code) {
        case(NSURLErrorDomain?, NSURLErrorNotConnectedToInternet?):
            print("I can haz interwebs? kthxbai")
            DntApi.instance.isOffline = true
        default:
            print("error: \(error)")
        }
    }
}