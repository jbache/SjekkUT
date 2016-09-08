//
//  DntManager.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 01/09/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import Alamofire
import CFNetwork

public class DntManager: Alamofire.Manager {

    var offlineRequests:[NSURLRequest]? = nil
    var isOffline:Bool = false {
        didSet {
            self.retryOfflineRequests()
        }
    }
    var baseUrl:String = ""
    var reachability:NetworkReachabilityManager? = nil

    public init(forDomain aDomain:String) {
        super.init()
        baseUrl = "https://" + aDomain
        loadOfflineRequests()

        if let anURL:NSURL = NSURL(string: baseUrl) {
            reachability = NetworkReachabilityManager(host: anURL.host!)
            reachability?.listener = { status in
                self.isOffline = !(self.reachability?.isReachable ?? true)
            }
            reachability?.startListening()
        }
    }

    deinit {
        if reachability != nil {
            reachability!.stopListening()
        }
    }

    override public func request(URLRequest: URLRequestConvertible) -> Request {
        // force using cache when offline
        if (isOffline && URLRequest.URLRequest.HTTPMethod == "GET") {
            URLRequest.URLRequest.cachePolicy = .ReturnCacheDataDontLoad
            print("offline request: \(URLRequest.URLRequest.URLString)")
        }
        return super.request(URLRequest)
    }

    func failHandler(error:NSError!, retryRequest aRequest:NSURLRequest? = nil) {

        isOffline = error.isOffline

        // if the request failed while offline, and is anything but GET, archive it to disk so it can be retried later
        if isOffline {
            if let theRequest = aRequest {
                addOfflineRequest(theRequest)
            }
        }
    }

    func offlineRequestFileString() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        let aURL = NSURL(string: baseUrl)
        if let aDirectoryString = paths.first {
            return aDirectoryString + "/" + (aURL?.host)! + "-offlineRequests"
        }
        return "/tmp/" + baseUrl + "-offlineRequests"
    }

    func saveOfflineRequests() -> Bool {
        let didArchive = NSKeyedArchiver.archiveRootObject(offlineRequests! as NSArray, toFile:offlineRequestFileString())
        if !didArchive {
            print("unable to archive")
        }
        return didArchive
    }

    func addOfflineRequest(aRequest:NSURLRequest) {

        // ignore all GET and HEAD requests
        if aRequest.HTTPMethod == "GET" || aRequest.HTTPMethod == "HEAD" {
            return
        }

        // add the request
        offlineRequests!.append(aRequest)
        // and update disk storage
        if !saveOfflineRequests() {
            // but if it failed, forget all about it
            // TODO: show an error dialog that persisting offline request failed
            offlineRequests!.removeLast()
        }
    }

    func loadOfflineRequests() {
        // attempt loading the requests from disk,
        offlineRequests = NSKeyedUnarchiver.unarchiveObjectWithFile(offlineRequestFileString()) as? [NSURLRequest]
        // or start with a blank one
        offlineRequests = offlineRequests ?? [NSURLRequest]()
    }

    func retryOfflineRequests() {
        // don't bother if we're offline
        if isOffline {
            return;
        }

        // copy the array to prevent response handlers from mutating while enumerating
        if let remainremainingRequests = self.offlineRequests {
            processRequestsSequentially(remainremainingRequests)
        }
    }

    func processRequestsSequentially(requests:[NSURLRequest]) {
        if let aRequest = requests.first {
            self.request(aRequest)
                .validate(statusCode: 200..<300)
                .responseJSON { response in
                    switch response.result {
                    case .Success:
                        self.removeCompletedRequest(aRequest)
                    case .Failure(let error):
                        // if the request is a catastrophic fail, don't retry it
                        if let httpStatusCode = response.response?.statusCode {
                            switch httpStatusCode {
                            case 400:
                                self.removeCompletedRequest(aRequest)
                            default:
                                break
                            }
                        }
                        print("failed syncing offline: \(error)")
                    }

                    // continue with the rest
                    let remainingCount = requests.count
                    let slice = requests[1..<remainingCount]
                    self.processRequestsSequentially(Array(slice))
            }
        }
    }

    func removeCompletedRequest(aRequest:NSURLRequest) {
        // if the request is associated with a offline/temporary managed object, delete it
        if let temporaryRequestIdString = aRequest.valueForHTTPHeaderField(kSjekkUtConstantTemporaryManagedObjectIdHeaderKey) {
            deleteManagedObjectForRequest(temporaryRequestIdString)
        }
        if let indexOfRequest = offlineRequests?.indexOf(aRequest) {
            offlineRequests?.removeAtIndex(indexOfRequest)
        }
        saveOfflineRequests()
    }

    func deleteManagedObjectForRequest(aRequestIdString:String) {
        if let aManagedObjectId = ModelController.instance().managedObjectContext.persistentStoreCoordinator?.managedObjectIDForURIRepresentation(NSURL(string: aRequestIdString)!) {
            let aManagedObject = ModelController.instance().managedObjectContext.objectWithID(aManagedObjectId)
            ModelController.instance().managedObjectContext.deleteObject(aManagedObject)
        }
    }
}