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
    var baseUrl:String = ""
    var api_key = ""

    init() {
        super.init()
    }

    convenience init(forDomain aDomain:String) {
        self.init()
        self.baseUrl = "https://" + aDomain
        self.api_key = (aDomain + ".api_key").loadFileContents(inClass:self.dynamicType)!
    }

    func getProjects() {
        self.request(.GET, baseUrl + "/lister", parameters: ["api_key": api_key])
            .responseJSON { response in
                if let aJSON = response.result.value {
                    // iterate over all entities
                    let someProjects = aJSON["documents"] as! [[String: AnyObject]]
                    // update or insert entities from API
                    for aProject in someProjects {
                        Project.insertOrUpdate(aProject)
                    }
                    // save the local database
                    ModelController.instance().save()
                }
            }
    }

    public func getProjectAndPlaces(projectId:String) {
        self.request(.GET, baseUrl + "/lister/" + projectId, parameters: ["api_key": api_key, "fields":"steder,geojson", "expand":"steder"])
            .responseJSON { response in
                if let aJSON = response.result.value {
                    // update or insert project from API
                    Project.insertOrUpdate(aJSON as! [String : AnyObject])
                    // save the local database
                    ModelController.instance().save()
                }
        }
    }
}