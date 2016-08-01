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
    let baseUrl = "https://www.dnt.no"
    var user:DntUser? = nil
    var clientId:String?
    var clientSecret:String?

    var isLoggedIn:Bool {
        get {
            let aToken = SSKeychain.passwordForService(SjekkUtKeychainServiceName, account: kSjekkUtDefaultsToken) as String?
            return aToken?.characters.count > 0
        }
    }

    var isExpired:Bool {
        get {
            if let expiryDate = NSUserDefaults.standardUserDefaults().objectForKey(kSjekkUtDefaultsTokenExpiry) as? NSDate {
                return expiryDate.compare(NSDate()) == .OrderedAscending
            }

            return false
        }
    }

    init () {
        super.init()
        self.setupCredentials()
    }

    func setupCredentials() {
        self.clientId = self.loadFileContents("www.dnt.no.client_id")
        self.clientSecret = self.loadFileContents("www.dnt.no.client_secret")
    }

    func loadFileContents(fileUrl:String) -> String? {
        let fileURL = NSBundle(forClass: self.dynamicType).URLForResource(fileUrl, withExtension: nil, subdirectory: nil)
        var fileContents:String?
        do {
            try fileContents = NSString(contentsOfURL: fileURL!, encoding: NSUTF8StringEncoding) as String
            fileContents = fileContents!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
        catch {
            print("failed to load file %@: %@", fileUrl, error)
        }
        return fileContents
    }

    func authorizeRequest() -> NSURLRequest {
        let loginUrl = "https://www.dnt.no/o/authorize/?" +
            "client_id=\(self.clientId!)&" +
            "response_type=code"
        let aRequest = NSURLRequest(URL: NSURL(string:loginUrl )!)
        return aRequest
    }


    func updateMemberDetailsOrFail( aFailureHandler : () -> Void ) {
        let aToken = SSKeychain.passwordForService( SjekkUtKeychainServiceName, account: kSjekkUtDefaultsToken)
        let someHeaders = ["Authorization":"Bearer " + aToken]
        self.request(.GET, baseUrl + "/api/oauth/medlemsdata/", headers: someHeaders)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    self.user = DntUser(jsonData: response.result.value as! [String: AnyObject])
                case .Failure(let error):
                    print("Validation failed: \(error)")
                    aFailureHandler()
                }
            }
    }

    func getTokenOrFail(authCode aCode:String, failure aFailureHandler: () -> Void) {
        let someParameters = [
            "grant_type": "authorization_code",
            "code": aCode,
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

                        self.login(tokenAccess, refreshToken: tokenRefresh)
                        print("refreshed token: \(JSON)")
                    }
                case .Failure(let anError):
                    print("error: \(anError)")
                    aFailHandler()
                }
        }
    }

    func login(authenticationCode:String, refreshToken aRefreshToken:String? = nil, expiry aTokenExpiry:Double? = nil) {

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
        NSNotificationCenter.defaultCenter().postNotificationName(kSjekkUtNotificationLoggedOut, object: nil)
    }
}