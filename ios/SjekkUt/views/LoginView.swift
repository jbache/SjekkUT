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

class LoginView: UIViewController, WKNavigationDelegate {

    var webView:WKWebView?
    let dntApi = DntApi.instance

    @IBOutlet weak var progressView: UIProgressView!

    // MARK: viewcontroller

    override func viewDidLoad() {
        setupLogin()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showProjectsView), name:kSjekkUtNotificationLogin, object: nil)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kSjekkUtNotificationLogin, object: nil)
    }

    // MARK: setup

    func setupLogin() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showLoginForm), name:kSjekkUtNotificationLoggedOut, object: nil)

        setupLoginForm()

        if (dntApi.isLoggedIn) {
            performSegueWithIdentifier("showProjectsImmediately", sender: nil)
        }
        else {
            dntApi.logout()
        }
    }

    func setupLoginForm() {
        // set up config with non-persistent datastore to prevent persistent login
        let webConfig = WKWebViewConfiguration()
        if #available(iOS 9.0, *) {
            webConfig.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore()
        } else {
            // Fallback on earlier versions
        }

        self.webView = WKWebView(frame: self.view.bounds, configuration: webConfig)
        self.webView?.navigationDelegate = self
        self.webView?.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        self.webView?.addObserver(self, forKeyPath: "estimatedProgress", options: .Initial, context: &kProgressContext)
        // insert at index 0 to land under the progress bar
        self.view.insertSubview(self.webView!, atIndex: 0)
    }

    // MARK: actions

    // jumps back to this view when client is logged out
    func showLoginForm() {
        self.navigationController?.popToViewController(self, animated: true)
        self.loadLoginForm()
    }

    func loadLoginForm() {
        let urlRequest = self.dntApi.authorizeRequest()
        if #available(iOS 9.0, *) {
            // need to remove all data to prevent user from seeing the authorization again
            // and instead see the login form
            webView?.configuration.websiteDataStore.removeDataOfTypes(WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: NSDate.distantPast(), completionHandler: { 
                self.webView?.loadRequest(urlRequest)
            })
        } else {
            self.webView?.loadRequest(urlRequest)
        }
    }

    func showProjectsView() {
        self.performSegueWithIdentifier("showProjects", sender: nil)
    }

    // MARK: observe

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &kProgressContext {
            let progressValue = Float((self.webView?.estimatedProgress)!)
            self.progressView.progress = progressValue
            // only show progress when it's between 0 and 1
            self.progressView.hidden = !(progressValue > 0 && progressValue < 1)
        }
    }

    // MARK: webkit

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void)
    {
        // if the URL is a callback with the access_token, log in
        let navigationUrl = navigationAction.request.URL?.absoluteString
        if navigationUrl!.containsString("callback") {
            decisionHandler(.Cancel)
            if navigationUrl!.containsString("code=") {
                let authCode = (navigationUrl?.componentsSeparatedByString("code=").last!)?.componentsSeparatedByString("&").first
                self.dntApi.getTokenOrFail(authCode:authCode!, failure:{ self.dntApi.logout()})
            }
            else {
                dntApi.logout()
            }
        }
        else {
            decisionHandler(.Allow)
        }
    }

    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        print("failed navigation: \(error)")
    }

    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        print("failed provisional navigation: \(error)")
    }
}