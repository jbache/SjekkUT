//
//  Turbasen.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 26/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import Alamofire

public class TurbasenApi: Alamofire.Manager {

    static let instance = TurbasenApi(forDomain:"dev.nasjonalturbase.no")

    var baseUrl:String = ""
    var api_key = ""

    init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(getPlaceNotification), name: kSjekkUtNotificationGetPlace, object: nil)
    }

    convenience init(forDomain aDomain:String) {
        self.init()
        self.baseUrl = "https://" + aDomain
        self.api_key = (aDomain + ".api_key").loadFileContents(inClass:self.dynamicType)!
    }

    @objc func getPlaceNotification(aNotification:NSNotification) {
        getPlace(aNotification.object as! Place)
    }

    func getPlace(aPlace:Place) {
        let parameters = [
            "api_key":api_key,
            "expand":"bilder"
        ]
        let placeUrl = baseUrl + "/steder/" + aPlace.identifier!
        self.request(.GET, placeUrl, parameters: parameters)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let aJSON = response.result.value {
                        ModelController.instance().saveBlock {
                            Place.insertOrUpdate(aJSON as! [NSObject : AnyObject])
                        }
                    }
                case .Failure(let error):
                    print("failed to get place \(placeUrl): \(error)")
                }

        }
    }

    func getProjectsAnd(finishHandler:((Void)->(Void)) ) {
        let parameters = [
            "api_key": api_key,
            "fields": "steder,bilder,geojson,grupper"
        ];
        self.request(.GET, baseUrl + "/lister", parameters:parameters )
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let aJSON = response.result.value {
                        // iterate over all entities
                        let someProjects = aJSON["documents"] as! [[String: AnyObject]]
                        // update or insert entities from API
                        ModelController.instance().saveBlock {
                            for aProjectDict in someProjects {
                                let aProject = Project.insertOrUpdate(aProjectDict)
                                self.getProjectAndPlaces(aProject)
                            }
                        }
                    }
                case .Failure(let error):
                    print("failed to get lists: \(error)")
            }
            finishHandler()
        }
    }

    func getProjects() {
        return getProjectsAnd {}
    }

    public func getProjectAndPlaces(aProject:Project) {
        let projectUrl = baseUrl + "/lister/" + aProject.identifier!
        let requestUrl = NSURL(string: projectUrl)!
        let urlRequest = NSMutableURLRequest(URL: requestUrl)
        urlRequest.HTTPMethod = "GET"
        urlRequest.cachePolicy = .ReloadIgnoringCacheData
        let parameters = ["api_key": api_key,
                          "fields":"steder,geojson,bilder,img,kommune,beskrivelse,grupper",
                          "expand":"steder,bilder,grupper"]
        self.request(.GET, urlRequest, parameters:parameters)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let aJSON = response.result.value {
                        ModelController.instance().saveBlock {
                            // update or insert project from API
                            let aProject:Project = Project.insertOrUpdate(aJSON as! [String : AnyObject])
                            for place in aProject.places! {
                                // fetch place with images
                                self.getPlace(place as! Place)
                                SjekkUtApi.instance.getPlaceCheckins(place as! Place)
                            }
                        }
                    }
                case .Failure(let error):
                    print("failed to get list \(projectUrl): \(error)")
                }
        }
    }
}