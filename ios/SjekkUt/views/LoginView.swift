//
//  Login.swift
//  SjekkUt
//
//  Created by Henrik Hartz on 25/07/16.
//  Copyright © 2016 Den Norske Turistforening. All rights reserved.
//

import UIKit
import WebKit

private var kProgressContext = 0
private let aClientId = "TdgJwdd6zvYlM2lZC933wWKVFb6nCvDqXa0EP9MP"
private let aClientSecret = "CMR7PYsfsQL9Vyh9RrFYmK5DD8Vb12jpyEMwQCCoTLz9tZClaICHXGVQHucp2oA4hBxOtDumf96utRAuBqRCTwbJj4tNvwQdfRo3OruPxg26Q2TSzPzj7iTYsxqvY6fG"


class LoginView: UIViewController, WKNavigationDelegate {

    var webView:WKWebView?
    let dntApi = DntApi()

    @IBOutlet weak var progressView: UIProgressView!

    override func viewDidLoad() {
        self.setupLoginForm()
        if (Backend.instance().isLoggedIn()) {
            self.performSegueWithIdentifier("showProjectsImmediately", sender: nil)
            dntApi.updateMemberDetailsOrFail {
                Backend.instance().logout()
                self.navigationController?.popToViewController(self, animated: true)
                self.loadLoginForm()
            }
        }
        else {
            self.loadLoginForm()
        }
    }

    func setupLoginForm() {
        self.webView = WKWebView(frame: self.view.bounds)
        self.webView?.navigationDelegate = self
        self.webView?.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        self.webView?.addObserver(self, forKeyPath: "estimatedProgress", options: .Initial, context: &kProgressContext)
        // insert at index 0 to land under the progress bar
        self.view.insertSubview(self.webView!, atIndex: 0)
    }

    func loadLoginForm() {
        let urlRequest = self.authorizeRequest()
        self.webView?.loadRequest(urlRequest)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &kProgressContext {
            let progressValue = Float((self.webView?.estimatedProgress)!)
            self.progressView.progress = progressValue
            // only show progress when it's between 0 and 1
            self.progressView.hidden = !(progressValue > 0 && progressValue < 1)
        }
    }

    // MARK: -
    // MARK: authorization
    func authorizeRequest() -> NSURLRequest {
        let loginUrl = "https://www.dnt.no/o/authorize/?" +
        "client_id=\(aClientId)&" +
        "client_secret=\(aClientSecret)&" +
        "response_type=token"
        let aRequest = NSURLRequest(URL: NSURL(string:loginUrl )!)
        return aRequest
    }

//    // not using this with implicit authorization
//    func tokenRequest(withAuthorizationCode code:NSString?) -> NSURLRequest {
//        let tokenUrl = "https://www.dnt.no/o/token/?" +
//            "client_id=\(aClientId)&" +
//            "client_secret=\(aClientSecret)&" +
//            "grant_type=authorization_code&" +
//            "code=\(code!)"
//        let urlRequest = NSURLRequest(URL: NSURL(string:tokenUrl)!)
//        return urlRequest
//    }

    // MARK: -
    // MARK: WebKit
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void)
    {
        // if the URL is a callback with the access_token, log in
        let navigationUrl = navigationAction.request.URL?.absoluteString
        if navigationUrl!.containsString("callback") && navigationUrl!.containsString("access_token=") {
            decisionHandler(.Cancel)
            let authCode = (navigationUrl?.componentsSeparatedByString("access_token=").last!)?.componentsSeparatedByString("&").first
            let backendInstance:Backend = Backend.instance()
            backendInstance.login(authCode)
            self.performSegueWithIdentifier("showProjects", sender: nil)
        }
        else {
            decisionHandler(.Allow)
        }
    }

// for SSL pinning
//    func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void)
//    func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
//        print("got challenge: \(challenge)")
//        comple
//    }

}