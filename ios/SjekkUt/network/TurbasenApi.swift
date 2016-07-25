//
//  Turbasen.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 26/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import Alamofire

let theDomain = "dev.nasjonalturbase.no"

public class TurbasenApi: Alamofire.Manager {

    var api_key = ""


    init() {
        super.init()
        api_key = TurbasenApi.apiKey()
    }

    static func apiKey() -> String {
        var api_key = ""
        do {
            let keyPath = NSBundle(forClass: self).URLForResource(theDomain + ".api_key", withExtension: nil, subdirectory: nil)
            try api_key = (NSString(contentsOfURL: keyPath!, encoding: NSUTF8StringEncoding) as String)
            api_key = api_key.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
        catch {
            fatalError("Failed to read key: \(error)")
        }
        return api_key
    }

    func baseUrl() -> String {
        return "https://" + theDomain
    }

    func getProjects() {
        self.request(.GET, baseUrl() + "/lister", parameters: ["api_key": api_key])
            .responseJSON { response in
                if let aJSON = response.result.value {
                    // iterate over all entities
                    let someProjects = aJSON["documents"] as! [[NSObject: NSObject]]
                    // update or insert entities from API
                    for aProject in someProjects {
                        Project.insertOrUpdate(aProject as! [NSString: NSObject])
                    }
                    // save the local database
                    ModelController.instance().save()
                }
            }
    }

    public func getProjectAndPlaces(projectId:String) {
        self.request(.GET, baseUrl() + "/lister/" + projectId, parameters: ["api_key": api_key, "fields":"steder", "expand":"steder"])
            .responseJSON { response in
                if let aJSON = response.result.value {
                    // update or insert project from API
                    let aProject:Project = Project.insertOrUpdate(aJSON as! [NSObject : AnyObject])
                    // update or insert places from API
                    let projectPlaces = NSMutableOrderedSet()
                    for aPlaceJson in aJSON["steder"] as! [[NSObject: NSObject]] {
                        let aPlace:Place = Place.insertOrUpdate(aPlaceJson)
                        projectPlaces.addObject(aPlace)
                    }
                    // add places to project
                    aProject.places = projectPlaces
                    // save the local database
                    ModelController.instance().save()
                }
        }
    }
}