//
//  Dnt.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 27/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import Alamofire
import SAMKeychain
import WebKit

class DntApi: DntManager {

    static let instance = DntApi(forDomain:"www.dnt.no")
    
    var clientId:String?
    var clientSecret:String?
    var successBlock:( () -> Void) = {}
    var failBlock:(()->Void) = {}
    override var isOffline:Bool {
        didSet {
            if isLoggedIn {
                self.updateMemberDetails()
            }
        }
    }

    var user:DntUser? {
        didSet {
            DntUser.setCurrentUser(user)
            if user != nil {
                NSNotificationCenter.defaultCenter().postNotificationName(kSjekkUtNotificationLoggedIn, object: nil)
            }
        }
    }

    var isLoggedIn:Bool {
        get {
            let aToken = SAMKeychain.passwordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsToken) as String?
            return user != nil && aToken?.characters.count > 0
        }
    }

    var isExpired:Bool {
        get {
            if let expiryDate = NSUserDefaults.standardUserDefaults().objectForKey(kSjekkUtDefaultsTokenExpiry) as? NSDate {
                print("token expires \(expiryDate)")
                return expiryDate.compare(NSDate()) == .OrderedAscending
            }

            return false
        }
    }


    override init(forDomain aDomain:String) {
        super.init(forDomain:aDomain)
        setupCredentials(domain:aDomain)
        setupUser()
    }

    // MARK: setup
    func setupCredentials(domain aDomain:String) {
        clientId = (aDomain + ".client_id").loadFileContents(inClass: self.dynamicType)
        clientSecret = (aDomain + ".client_secret").loadFileContents(inClass: self.dynamicType)
    }

    func setupUser() {
        if let aUserId = SAMKeychain.passwordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsUserId) {
            user = DntUser.findWithId(aUserId)
            DntUser.setCurrentUser(user)
        }
    }



    // MARK: Oauth 2

    func authorizeRequest() -> NSURLRequest {
        let loginUrl = baseUrl + "/o/authorize/?" +
            "client_id=\(clientId!)&" +
            "response_type=code"
        let aRequest = NSMutableURLRequest(URL: NSURL(string:loginUrl )!)
        aRequest.cachePolicy = .ReloadIgnoringLocalAndRemoteCacheData
        return aRequest
    }

    func getToken(authCode aCode:String) {
        let someParameters = [
            "grant_type": "authorization_code",
            "code": aCode,
            "redirect_uri": "https://localhost/callback",
            "client_id" : clientId!,
            "client_secret" : clientSecret!
        ]
        self.request(.POST, baseUrl + "/o/token/", parameters:someParameters, encoding: .URL)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let JSON = response.result.value {
                        let tokenRefresh = JSON["refresh_token"] as! String
                        let tokenAuthentication = JSON["access_token"] as! String
                        let tokenExpiry = JSON["expires_in"] as! Double
                        self.authorized(tokenAuthentication, refreshToken: tokenRefresh, expiry: tokenExpiry)
                        self.didSucceed()
                    }
                case .Failure(let error):
                    self.failHandler(error)
                    self.didFail()
                }
            }
    }

    func refreshToken() {

        let refreshToken = SAMKeychain.passwordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsRefreshToken)

        if (refreshToken == nil) {
            self.didFail()
            return
        }

        let someParameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "redirect_uri": "https://localhost/callback",
            "client_id" : self.clientId!,
            "client_secret" : self.clientSecret!
        ]

        self.request(.POST, baseUrl + "/o/token/", parameters:someParameters, encoding: .URL)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let JSON = response.result.value {
                        let tokenAccess = JSON["access_token"] as! String
                        let tokenRefresh = JSON["refresh_token"] as! String
                        self.authorized(tokenAccess, refreshToken: tokenRefresh)
                        self.didSucceed()
                        print("refreshed token: \(JSON)")
                    }
                case .Failure(let anError):
                    self.failHandler(anError)
                    self.didFail()
                }
        }
    }

    // MARK: login and logout

    func authorized(authenticationCode:String, refreshToken aRefreshToken:String? = nil, expiry aTokenExpiry:Double? = nil) {

        // update or remove expiry
        if let tokenExpiry = aTokenExpiry {
            let expiry =  NSDate().dateByAddingTimeInterval(NSTimeInterval(tokenExpiry))
            NSUserDefaults.standardUserDefaults().setObject(expiry, forKey: kSjekkUtDefaultsTokenExpiry)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        else {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(kSjekkUtDefaultsTokenExpiry)
            NSUserDefaults.standardUserDefaults().synchronize()
        }

        // update or remove refresh token
        if let refreshToken = aRefreshToken {
            SAMKeychain.setPassword(refreshToken, forService: SjekkUtKeychainServiceName, account: kSjekkUtDefaultsRefreshToken)
        }
        else {
            SAMKeychain.deletePasswordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsRefreshToken)
        }

        SAMKeychain.setPassword(authenticationCode, forService: SjekkUtKeychainServiceName, account: kSjekkUtDefaultsToken)

        NSNotificationCenter.defaultCenter().postNotificationName(kSjekkUtNotificationAuthorized, object: nil)
    }

    func login(aUser:DntUser) {
        SAMKeychain.setPassword(aUser.identifier, forService: SjekkUtKeychainServiceName, account: kSjekkUtDefaultsUserId)
        user = aUser
    }

    func logout() {
        user = nil
        // clear out all cookies
        let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        for cookie in storage.cookies! {
            storage.deleteCookie(cookie)
        }

        // delete all personal database entities
        Checkin.deleteAll()
        Project.deleteAll()
        DntUser.deleteAll()

        // remove tokens
        SAMKeychain.deletePasswordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsToken)
        SAMKeychain.deletePasswordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsRefreshToken)
        SAMKeychain.deletePasswordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsUserId)

        // remove expiry
        NSUserDefaults.standardUserDefaults().removeObjectForKey(kSjekkUtDefaultsTokenExpiry)
        NSUserDefaults.standardUserDefaults().synchronize()

        // tell the world
        NSNotificationCenter.defaultCenter().postNotificationName(kSjekkUtNotificationLoggedOut, object: nil)
    }

    // MARK: REST api

    func updateMemberDetails() {

        if isOffline {
            return
        }

        let aToken = SAMKeychain.passwordForService( SjekkUtKeychainServiceName, account: kSjekkUtDefaultsToken)

        // if there is no token, assume failure
        if (aToken == nil) {
            didFail()
            return
        }

        // if we're offline we can just move on
        if (isOffline || !(reachability?.isReachable)! ) {
            didSucceed()
            return
        }

        let someHeaders = ["Authorization":"Bearer " + aToken]

        self.request(.GET, baseUrl + "/api/oauth/medlemsdata/", headers: someHeaders)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let aUser:DntUser = DntUser.insertOrUpdate(response.result.value as! [String: AnyObject]) {
                        self.login(aUser)
                        self.didSucceed()
                    }
                    else {
                        self.didFail()
                    }
                case .Failure(let error):
                    if let httpStatusCode = response.response?.statusCode {
                        switch httpStatusCode {
                        case 403:
                            self.refreshToken()
                        default:
                            self.failHandler(error)
                            self.didFail()
                        }
                    }
                }
        }
    }

    func didSucceed() {
        successBlock()
    }

    func didFail() {
        failBlock()
    }
}