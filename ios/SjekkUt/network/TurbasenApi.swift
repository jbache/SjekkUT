//
//  Turbasen.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 26/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import Alamofire

public class TurbasenApi: DntManager {

    static let instance = TurbasenApi(forDomain:"dev.nasjonalturbase.no")

    let projectFields:String = "steder,geojson,bilder,img,grupper,lenker,start,stopp,fylke,kommune"
    var baseUrl:String = ""
    var api_key = ""
    let locationController = Location.instance()

    var isObserving:Bool = false
    var kObserveLocation = 0

    convenience init(forDomain aDomain:String) {
        self.init()
        self.baseUrl = "https://" + aDomain
        self.api_key = (aDomain + ".api_key").loadFileContents(inClass:self.dynamicType)!
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateDistance), name: kSjekkUtNotificationLocationChanged, object: nil)
        locationController.startUpdate()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        locationController.stopUpdate()
    }


    // MARK: place

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
                    self.failHandler(error)
                }

        }
    }

    // MARK: projects

    func getProjectsAnd(finishHandler:((Void)->(Void)) ) {
        let parameters = [
            "api_key": api_key,
            "fields": projectFields
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

                            // prevent upstream deleted projects from showing
                            for aProject:Project in Project.allEntities() as! [Project] {
                                aProject.isHidden = true
                            }

                            for aProjectDict in someProjects {
                                let aProject = Project.insertOrUpdate(aProjectDict)
                                aProject.isHidden = false
                                self.getProjectAnd(aProject) {_ in }
                            }
                        }
                    }
                case .Failure(let error):
                    self.failHandler(error)
            }
            finishHandler()
        }
    }

    func getProjects() {
        return getProjectsAnd {}
    }


    // MARK: project

    public func getProjectAnd( aProject:Project, _ projectHandler:Project->Void ) {
        let projectUrl = baseUrl + "/lister/" + aProject.identifier!
        let requestUrl = NSURL(string: projectUrl)!
        let urlRequest = NSMutableURLRequest(URL: requestUrl)
        urlRequest.HTTPMethod = "GET"
        urlRequest.cachePolicy = .ReloadIgnoringCacheData
        let parameters = ["api_key": api_key,
                          "fields": projectFields,
                          "expand":"steder,bilder,grupper"]
        self.request(.GET, urlRequest, parameters:parameters)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let aJSON = response.result.value {
                        ModelController.instance().saveBlock {
                            // update or insert project from API
                            let theProject:Project = Project.insertOrUpdate(aJSON as! [String : AnyObject])
                            projectHandler(theProject)
                        }
                    }
                case .Failure(let error):
                    self.failHandler(error)
                }
        }
    }

    public func getProjectAndPlaces(aProject:Project) {
        getProjectAnd(aProject) { (theProject: Project) -> Void in
            for place in theProject.places! {
                // fetch place with images
                self.getPlace(place as! Place)
            }
        }
    }

    // MARK: distance
    @objc func updateDistance() {
        ModelController.instance().saveBlock {
            for aProject in Project.allEntities() as! [Project] {
                aProject.updateDistance()
            }
        }
    }
}