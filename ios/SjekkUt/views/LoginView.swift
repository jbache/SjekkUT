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
    var dntApi:DntApi?

    @IBOutlet weak var progressView: UIProgressView!

    // MARK: viewcontroller

    override func viewDidLoad() {
        self.setupLogin()

        ModelController.instance().delayUntilReady {
            // need to wait until database is ready to allow fetching persisted user data
            self.dntApi = DntApi.instance
            self.tryLogin()
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kSjekkUtNotificationLoggedIn, object: nil)
    }

    // MARK: setup

    func setupLogin() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(showLoginForm), name:kSjekkUtNotificationLoggedOut, object: nil)

        setupLoginForm()
    }

    func setupLoginForm() {
        // set up config with non-persistent datastore to prevent persistent login
        let webConfig = WKWebViewConfiguration()
        if #available(iOS 9.0, *) {
            webConfig.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore()
        } else {
            // Fallback on earlier versions
        }

        webView = WKWebView(frame: view.bounds, configuration: webConfig)
        webView?.navigationDelegate = self
        webView?.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        webView?.addObserver(self, forKeyPath: "estimatedProgress", options: .Initial, context: &kProgressContext)
        // insert at index 0 to land under the progress bar
        view.insertSubview(self.webView!, atIndex: 0)
    }

    // MARK: actions

    func tryLogin() {
        dntApi?.successBlock = {
            self.showMainView()
            self.dntApi?.successBlock = {}
            self.dntApi?.failBlock = {}
        }
        dntApi?.failBlock = {
            self.dntApi?.logout()
            self.dntApi?.successBlock = {}
            self.dntApi?.failBlock = {}
        }
        dntApi?.updateMemberDetails()
    }

    // jumps back to this view when client is logged out
    func showLoginForm() {
        navigationController?.popToViewController(self, animated: true)
        loadLoginForm()

        // initial authorization will steal success and fail blocks in 'tryLogin' to progress
        // with login
        dntApi?.failBlock = {
            self.dntApi?.logout()
        }
        dntApi?.successBlock = {
            self.tryLogin()
        }
    }

    func loadLoginForm() {
        let urlRequest = self.dntApi!.authorizeRequest()
        if #available(iOS 9.0, *) {
            // need to remove all data to prevent user from seeing the authorization again
            // and instead see the login form
            webView?.configuration.websiteDataStore.removeDataOfTypes(WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: NSDate.distantPast(), completionHandler: { 
                self.webView?.loadRequest(urlRequest)
            })
        } else {
            webView?.loadRequest(urlRequest)
        }
    }

    func showMainView() {
        ModelController.instance().delayUntilReady {
            self.performSegueWithIdentifier("showProjects", sender: nil)
        }
    }

    // MARK: observe

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &kProgressContext {
            let progressValue = Float((webView?.estimatedProgress)!)
            progressView.progress = progressValue
            // only show progress when it's between 0 and 1
            progressView.hidden = !(progressValue > 0 && progressValue < 1)
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
                self.dntApi!.getToken(authCode:authCode!)
            }
            else {
                dntApi!.didFail()
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