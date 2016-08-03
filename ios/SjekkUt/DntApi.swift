//
//  Dnt.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 27/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import Foundation
import Alamofire
import SSKeychain
import WebKit

class DntUser {
    let firstName:String
    let lastName:String
    let dntId:Double

    init(jsonData:[String: AnyObject]) {
        firstName = jsonData["fornavn"] as! String
        lastName = jsonData["etternavn"] as! String
        dntId = jsonData["sherpa_id"] as! Double
    }
}

class DntApi: Alamofire.Manager {

    static let instance = DntApi(forDomain:"www.dnt.no")

    var baseUrl:String?
    var user:DntUser? = nil
    var clientId:String?
    var clientSecret:String?
    var loginBlock:( () -> Void) = {}

    var isLoggedIn:Bool {
        get {
            let aToken = SSKeychain.passwordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsToken) as String?
            return aToken?.characters.count > 0
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

    convenience init(forDomain aDomain:String) {
        self.init()
        baseUrl = "https://" + aDomain
        setupCredentials(domain:aDomain)
    }

    // MARK: setup
    func setupCredentials(domain aDomain:String) {
        clientId = (aDomain + ".client_id").loadFileContents(inClass: self.dynamicType)
        clientSecret = (aDomain + ".client_secret").loadFileContents(inClass: self.dynamicType)
    }

    // MARK: Oauth 2

    func authorizeRequest() -> NSURLRequest {
        let loginUrl = baseUrl! + "/o/authorize/?" +
            "client_id=\(clientId!)&" +
            "response_type=code"
        let aRequest = NSURLRequest(URL: NSURL(string:loginUrl )!)
        return aRequest
    }

    func getTokenOrFail(authCode aCode:String, failure aFailureHandler: () -> Void) {
        let someParameters = [
            "grant_type": "authorization_code",
            "code": aCode,
            "redirect_uri": "https://localhost/callback",
            "client_id" : clientId!,
            "client_secret" : clientSecret!
        ]
        self.request(.POST, baseUrl! + "/o/token/", parameters:someParameters, encoding: .URL)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let JSON = response.result.value {
                        let tokenRefresh = JSON["refresh_token"] as! String
                        let tokenAuthentication = JSON["access_token"] as! String
                        let tokenExpiry = JSON["expires_in"] as! Double
                        self.login(tokenAuthentication, refreshToken: tokenRefresh, expiry: tokenExpiry)
                    }
                case .Failure(let error):
                    print("failed to get token: \(error)")
                    aFailureHandler()
                }
            }
    }

    func refreshTokenOrFail(aFailHandler: () -> Void) {

        let refreshToken = SSKeychain.passwordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsRefreshToken)

        if (refreshToken == nil) {
            self.logout()
            return
        }

        let someParameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "redirect_uri": "https://localhost/callback",
            "client_id" : self.clientId!,
            "client_secret" : self.clientSecret!
        ]

        self.request(.POST, baseUrl! + "/o/token/", parameters:someParameters, encoding: .URL)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    if let JSON = response.result.value {
                        let tokenAccess = JSON["access_token"] as! String
                        let tokenRefresh = JSON["refresh_token"] as! String

                        self.login(tokenAccess, refreshToken: tokenRefresh)
                        print("refreshed token: \(JSON)")
                    }
                case .Failure(let anError):
                    print("token refresh failed: \(anError)")
                    aFailHandler()
                }
        }
    }

    // MARK: login and logout

    func login(authenticationCode:String, refreshToken aRefreshToken:String? = nil, expiry aTokenExpiry:Double? = nil) {

        self.loginBlock()
        self.loginBlock = {}

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
            SSKeychain.setPassword(refreshToken, forService: SjekkUtKeychainServiceName, account: kSjekkUtDefaultsRefreshToken)
        }
        else {
            SSKeychain.deletePasswordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsRefreshToken)

        }

        SSKeychain.setPassword(authenticationCode, forService: SjekkUtKeychainServiceName, account: kSjekkUtDefaultsToken)
        NSNotificationCenter.defaultCenter().postNotificationName(kSjekkUtNotificationLogin, object: nil)
    }

    func logout() {
        SSKeychain.deletePasswordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsToken)
        SSKeychain.deletePasswordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsRefreshToken)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(kSjekkUtDefaultsTokenExpiry)
        NSUserDefaults.standardUserDefaults().synchronize()

        NSNotificationCenter.defaultCenter().postNotificationName(kSjekkUtNotificationLoggedOut, object: nil)
    }

    // MARK: REST api

    func updateMemberDetailsOrFail( aFailureHandler : () -> Void ) {

        let aToken = SSKeychain.passwordForService( SjekkUtKeychainServiceName, account: kSjekkUtDefaultsToken)
        let someHeaders = ["Authorization":"Bearer " + aToken]

        self.request(.GET, baseUrl! + "/api/oauth/medlemsdata/", headers: someHeaders)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    self.user = DntUser(jsonData: response.result.value as! [String: AnyObject])
                case .Failure(let error):
                    if let httpStatusCode = response.response?.statusCode {
                        switch httpStatusCode {
                        case 403:
                            self.loginBlock = { self.updateMemberDetailsOrFail{} }
                            self.refreshTokenOrFail(aFailureHandler)
                        default:
                            print("Validation failed: \(error)")
                            aFailureHandler()
                        }
                    }
                }
        }
    }
}