//
//  Dnt.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 27/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import Alamofire
import SSKeychain

class DntUser {
    let firstName:String
    let lastName:String
    let dntId:Double

    init(jsonData:[String: AnyObject]) {
        firstName = jsonData["fornavn"] as! String
        lastName = jsonData["etternavn"] as! String
        dntId = jsonData["sherpa_id"] as! Double
    }
}

class DntApi: Alamofire.Manager {
    let baseUrl = "https://www.dnt.no/api"
    var user:DntUser? = nil

    func updateMemberDetailsOrFail( aFailureHandler : () -> Void ) {
        let aToken = SSKeychain.passwordForService( SjekkUtKeychainServiceName, account: kSjekkUtDefaultsToken)
        let someHeaders = ["Authorization":"Bearer " + aToken]
        self.request(.GET, baseUrl + "/oauth/medlemsdata/", headers: someHeaders)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    self.user = DntUser(jsonData: response.result.value as! [String: AnyObject])
                case .Failure(let error):
                    print("Validation failed: \(error)")
                    aFailureHandler()
                }
            }
    }
}