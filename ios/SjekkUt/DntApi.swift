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

class DntApi: Alamofire.Manager {
    let baseUrl = "https://www.dnt.no/api"

    func updateMemberDetailsOrFail( aFailureHandler : () -> Void ) {
        let headers = ["Authorization":"Bearer " + SSKeychain.passwordForService( SjekkUtKeychainServiceName, account: kSjekkUtDefaultsToken)]
        self.request(.GET, baseUrl + "/oauth/medlemsdata/", headers: headers)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    print("Validation Successful")
                case .Failure(let error):
                    print("Validation failed: \(error)")
                    aFailureHandler()
                }
            }
    }
}