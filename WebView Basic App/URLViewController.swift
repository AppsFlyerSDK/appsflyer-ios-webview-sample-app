//
//  URLViewController.swift
//  WebView Basic App
//
//  Created by eunjoo on 2023/12/01.
//

import UIKit
import WebKit
import AppsFlyerLib

class URLViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // WebView setting
        let preferences = WKPreferences()
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // URL setting
        let components = URLComponents(string: "https://appsflyersdk.github.io/webview-http-sample-page/urlloading.html")!
        
        let request = URLRequest(url: components.url!)
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.load(request)
        
        // add custom value to userAgent to identify iOS WebView environment
        webView.evaluateJavaScript("navigator.userAgent") { [weak webView] (result, error) in
            if let webView = webView, let userAgent = result as? String {
                webView.customUserAgent = userAgent + "/iOS_WebView"
            }
        }
    }

    // to report event to AppsFlyer
    func webView(_ view: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
        decisionHandler(.allow)
        let pageUrl = navigationAction.request.url?.absoluteString
        if (pageUrl?.hasPrefix("af-event://") ?? false) {
            let scanner = Scanner(string: pageUrl!)
            scanner.charactersToBeSkipped = CharacterSet(charactersIn: "&?")
            _ = scanner.scanUpToString("?")

            var eventValue: [String: String] = Dictionary()
            var eventName: String?

            while let tempString = scanner.scanUpToString("&") {
                if tempString.hasPrefix("eventName=") && tempString.count > 10 {
                    eventName = String(tempString.dropFirst(10))
                }
                if tempString.hasPrefix("eventValue=") && tempString.count > 11 {
                    let eventValues = tempString.components(separatedBy: "=")[1].removingPercentEncoding
                    if let eventValuesData = eventValues?.data(using: String.Encoding.utf8) {
                        do {
                            if let value = try JSONSerialization.jsonObject(with: eventValuesData, options:[]) as? [String: String] {
                                eventValue = value
                            }
                        } catch let error as NSError {
                            print(error)
                        }
                    }
                }
            }
            
            if (eventName != nil) {
                if let eventName = eventName {
                    // record event
                    AppsFlyerLib.shared().logEvent((eventName as String?)!, withValues: eventValue)
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
