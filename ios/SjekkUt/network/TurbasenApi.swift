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
        self.request(.GET, baseUrl + "/steder/" + aPlace.identifier!, parameters: parameters)
            .responseJSON { response in
                if let aJSON = response.result.value {
                        ModelController.instance().saveBlock {
                            Place.insertOrUpdate(aJSON as! [NSObject : AnyObject])
                        }
                }
        }
    }

    func getProjects() {
        self.request(.GET, baseUrl + "/lister", parameters: ["api_key": api_key])
            .responseJSON { response in
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
                }
            }
    }

    public func getProjectAndPlaces(projectId:String) {
        let requestUrl = NSURL(string: baseUrl + "/lister/" + projectId)!
        let urlRequest = NSMutableURLRequest(URL: requestUrl)
        urlRequest.HTTPMethod = "GET"
        urlRequest.cachePolicy = .ReloadIgnoringCacheData
        let parameters = ["api_key": api_key,
                          "fields":"steder,geojson,bilder,img,kommune,beskrivelse",
                          "expand":"steder,bilder"]
        self.request(.GET, urlRequest, parameters:parameters)
            .responseJSON { response in
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
        }
    }
}