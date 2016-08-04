//
//  SjekkUt.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 27/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import Alamofire
import SSKeychain

class SjekkUtApi: Alamofire.Manager {

    static let instance = SjekkUtApi(forDomain:"sjekkut.app.dnt.no")

    var baseUrl:String = ""
    var dntUser:DntUser?

    init() {
        super.init()
    }

    convenience init(forDomain aDomain:String) {
        self.init()
        baseUrl = "https://" + aDomain + "/v1"
    }

    func getPlaceStats(aPlace:Place) {
        let requestUrl = baseUrl + "/steder/\(aPlace.identifier!)/stats"
        self.request(.GET, requestUrl)
            .validate(statusCode:200..<300)
            .responseJSON { response in
                print("getPlaceStats: \(response.result)")
        }
    }

    func getPlaceLog(aPlace:Place) {

    }

    func doPlaceVisit(aPlace:Place, finishHandler:(result:Result<AnyObject,NSError>)->()) {
        let currentLocation = Location.instance().currentLocation.coordinate
        let someParameters = [
            "lat":currentLocation.latitude,
            "lon":currentLocation.longitude
        ]
        let someHeaders:[String:String]? = [
            "X-User-Id": "\(Int((DntApi.instance.user?.dntId)!))",
            "X-User-Token": SSKeychain.passwordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsToken)
        ]
        let requestUrl = baseUrl + "/steder/\(aPlace.identifier!)/besok"
        let request = self.request(.POST, requestUrl, parameters:someParameters, headers:someHeaders, encoding: .JSON)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let json = response.result.value {
                        let checkin = Checkin.insertOrUpdate(json as! [String : AnyObject])
                        aPlace.addCheckinsObject(checkin)
                        ModelController.instance().save()
                        NSNotificationCenter.defaultCenter().postNotificationName(SjekkUtCheckedInNotification, object:checkin);
                    }
                case .Failure(let error):
                    print("failed to visit place: \(error)")

                }
                finishHandler(result: response.result)
        }

        debugPrint(request)
    }
    
}