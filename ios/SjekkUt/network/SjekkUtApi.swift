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

class SjekkUtApi: Alamofire.Manager {

    static let instance = SjekkUtApi(forDomain:"sjekkut.app.dnt.no")
    let authenticationHeaders:[String:String]? = [
        "X-User-Id": "\((DntApi.instance.user?.identifier)!)",
        "X-User-Token": SAMKeychain.passwordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsToken)
    ]


    var baseUrl:String = ""

    init() {
        super.init()
    }

    convenience init(forDomain aDomain:String) {
        self.init()
        baseUrl = "https://" + aDomain + "/v2"
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
                    print("failed to get profile: \(error)")
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
                leaveProject.removeAtIndex(leaveProject.indexOf(aProject)!)
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
                    print("failed to join project: \(error)")

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
                    print("failed to leave project: \(error)")

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

    func doPlaceCheckin(aPlace:Place, finishHandler:(result:Result<AnyObject,NSError>)->()) {
        let currentLocation = Location.instance().currentLocation.coordinate
        let someParameters = [
            "lat":currentLocation.latitude,
            "lon":currentLocation.longitude,
            "public":(DntApi.instance.user?.publicCheckins?.boolValue)!
        ]
        let requestUrl = baseUrl + "/steder/\(aPlace.identifier!)/besok"
        self.request(.POST, requestUrl, parameters:someParameters as? [String : AnyObject], headers:authenticationHeaders, encoding: .JSON)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
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
                    print("failed to visit place: \(error)")

                }
                finishHandler(result: response.result)
        }
    }

    func doChangePublicCheckin(enablePublicCheckin:Bool, finishHandler:((Void)->(Void))) {
        ModelController.instance().saveBlock { 
            DntApi.instance.user?.publicCheckins = enablePublicCheckin
            finishHandler()
        }
    }
}