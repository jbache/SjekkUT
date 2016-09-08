//
//  SjekkUt.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 27/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import AlamofireSwiftyJSON
import SAMKeychain

class SjekkUtApi: DntManager {

    static let instance = SjekkUtApi(forDomain:"sjekkut.app.dnt.no/v2")

    var authenticationHeaders:[String:String]! {
        get {
            return [
                "X-User-Id": "\((DntApi.instance.user?.identifier)!)",
                "X-User-Token": SAMKeychain.passwordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsToken)
            ]
        }
    }

    override var isOffline:Bool {
        didSet {
            if isOffline != oldValue {
                // delay to allow reporting offline requests
                delay(2) {
                    self.getProfile()
                }
            }
        }
    }


    // MARK: profile

    func getProfile() {
        let requestUrl = baseUrl + "/brukere/\( (DntApi.instance.user?.identifier)!)"
        self.request(.GET, requestUrl, headers:authenticationHeaders)
            .validate(statusCode:200..<300)
            .responseSwiftyJSON { response in
                switch response.result {
                case .Success:
                    self.parseProfile(response.result.value!["data"])
                case .Failure(let error):
                    self.failHandler(error)
                }
        }
    }

    func parseProfile(json:JSON) {
        if let checkinsJSON = json["innsjekkinger"].array {
            self.updateCheckins(checkinsJSON)
        }
        if let projectsJSON = json["lister"].array {
            self.updateProjects(projectsJSON)
        }
    }

    // MARK: projects

    func updateProjects(projectsArray:[JSON]) {
        ModelController.instance().saveBlock {
            var leaveProject = Project.allEntities() as! [Project]

            for projectJSON in projectsArray {
                let aProject = Project.insertOrUpdate(projectJSON.string!)
                if (aProject.isParticipating == nil) {
                    aProject.isParticipating = true
                }
                // only change record if it's different
                if (!aProject.isParticipating!.boolValue) {
                    aProject.isParticipating = true
                }

                if let projectIndex = leaveProject.indexOf(aProject) {
                    leaveProject.removeAtIndex(projectIndex)
                }
            }

            // not participating in remaining objects
            for aProject:Project in leaveProject {
                if (aProject.isParticipating!.boolValue) {
                    aProject.isParticipating = false
                }
            }
        }
    }

    func doJoinProject(aProject:Project, completionHandler:((Void)->(Void))) {
        let requestUrl = baseUrl + "/lister/\(aProject.identifier!)/blimed"
        self.request(.POST, requestUrl, headers:authenticationHeaders, encoding: .JSON)
            .validate(statusCode: 200..<300)
            .responseSwiftyJSON { response in
                switch response.result {
                case .Success:
                    if let json:JSON = response.result.value {
                        self.parseProfile(json["data"])
                    }
                case .Failure(let error):
                    // in the case of offline we need to specify that the request should be retried when
                    // the device comes back online
                    var aRetryRequest:NSURLRequest? = nil
                    if (self.isOffline || error.isOffline) {
                        aProject.isParticipating = true
                        aRetryRequest = response.request
                    }
                    self.failHandler(error, retryRequest: aRetryRequest)
                }
                completionHandler()
        }
    }

    func doLeaveProject(aProject:Project, completionHandler:((Void)->(Void))) {
        let requestUrl = baseUrl + "/lister/\(aProject.identifier!)/meldav"
        self.request(.POST, requestUrl, headers:authenticationHeaders, encoding: .JSON)
            .validate(statusCode: 200..<300)
            .responseSwiftyJSON { response in
                switch response.result {
                case .Success:
                    if let json:JSON = response.result.value {
                        self.parseProfile(json["data"])
                    }
                case .Failure(let error):
                    // in the case of offline we need to specify that the request should be retried when
                    // the device comes back online
                    var aRetryRequest:NSURLRequest? = nil
                    if (self.isOffline || error.isOffline) {
                        aProject.isParticipating = false
                        aRetryRequest = response.request
                    }
                    self.failHandler(error, retryRequest: aRetryRequest)

                }
                completionHandler()
        }
    }


    // MARK: checkins

    func updateCheckins(checkinsArray:[JSON]) {
        ModelController.instance().saveBlock {
            for checkinJson in checkinsArray {
                if "\(checkinJson["dnt_user_id"])" == DntApi.instance.user?.identifier {
                    _ = Checkin.insertOrUpdate(checkinJson.dictionaryObject!)
                }
            }
        }
    }

    func getPlaceCheckins(aPlace:Place) {
        let requestUrl = baseUrl + "/steder/\(aPlace.identifier!)/logg"
        self.request(.GET, requestUrl)
            .validate(statusCode:200..<300)
            .responseSwiftyJSON { response in
                if let checkinsJson:JSON = response.result.value!["data"] {
                    self.updateCheckins(checkinsJson.array!)
                }
        }
    }

    func doPlaceCheckin(aPlace:Place, finishHandler:(response:Response<AnyObject, NSError>)->()) {
        let currentLocation = Location.instance().currentLocation.coordinate
        let someParameters = [
            "lat": currentLocation.latitude,
            "lon": currentLocation.longitude,
            "public":(DntApi.instance.user?.publicCheckins?.boolValue)!,
            "timestamp": Checkin.dateFormatter().stringFromDate(NSDate()),
        ]
        let requestUrl = baseUrl + "/steder/\(aPlace.identifier!)/besok"
        request(.POST, requestUrl, parameters:someParameters as? [String : AnyObject], headers:authenticationHeaders)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                // in the case of offline checkins we need to fake a successful result for the finish handler
                var aResponse = response
                switch response.result {
                case .Success:
                    if let json = response.result.value {
                        ModelController.instance().saveBlock {
                            let checkin = Checkin.insertOrUpdate(json["data"] as! [String : AnyObject])
                            aPlace.addCheckinsObject(checkin)
                            NSNotificationCenter.defaultCenter().postNotificationName(SjekkUtCheckedInNotification, object:checkin);
                        }
                    }
                case .Failure(let error):

                    // in the case of offline checkins we need to specify that the request should be retried when 
                    // the device comes back online
                    var aRetryRequest:NSMutableURLRequest? = nil

                    if (self.isOffline || error.isOffline) {

                        // a random identifier we can use to update the entity with the API data when it POSTs the actual
                        // checkin
                        let aRandomId = "offline-\(NSUUID().UUIDString)"

                        ModelController.instance().saveBlock {
                            let checkin = Checkin.insert() as! Checkin
                            checkin.identifier = aRandomId
                            checkin.date = NSDate()
                            checkin.latitute = currentLocation.latitude
                            checkin.longitude = currentLocation.longitude
                            checkin.isOffline = true
                            checkin.isPublic = (DntApi.instance.user?.publicCheckins?.boolValue)!
                            checkin.user = DntApi.instance.user
                            aPlace.addCheckinsObject(checkin)
                            NSNotificationCenter.defaultCenter().postNotificationName(SjekkUtCheckedInNotification, object:checkin);

                            // store the temporary ID and retry the operation later
                            let offlineRequest:NSMutableURLRequest = response.request?.mutableCopy() as! NSMutableURLRequest
                            offlineRequest.setValue(checkin.objectID.URIRepresentation().absoluteString, forHTTPHeaderField: kSjekkUtConstantTemporaryManagedObjectIdHeaderKey)
                            aRetryRequest = offlineRequest

                            // fake correct result
                            aResponse = Response(request: response.request, response: response.response, data: response.data, result: .Success("asdf"))
                        }
                    }
                    self.failHandler(error, retryRequest: aRetryRequest)
                }
                finishHandler(response: aResponse)
        }
    }

    func doChangePublicCheckin(enablePublicCheckin:Bool, finishHandler:((Void)->(Void))) {
        ModelController.instance().saveBlock { 
            DntApi.instance.user?.publicCheckins = enablePublicCheckin
            finishHandler()
        }
    }
}
