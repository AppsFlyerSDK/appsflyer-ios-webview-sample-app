//
//  JSWebViewController.swift
//  WebView Basic App
//
//  Created by eunjoo on 2023/12/01.
//

import UIKit
import WebKit
import AppsFlyerLib

// Add WKScriptMessageHandler as a way to respond to JavaScript messages in the web view.
class JSWebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {

    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // WebView setting
        let preferences = WKPreferences()
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // URL setting
        let components = URLComponents(string: "https://appsflyersdk.github.io/webview-http-sample-page/jsinterface.html")!
        let request = URLRequest(url: components.url!)
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.load(request)
        webView.configuration.userContentController.add(self, name:"event")
        
        // inject JS to capture console.log output and send to iOS
        let source = "function captureLog(msg) { window.webkit.messageHandlers.logHandler.postMessage(msg); } window.console.log = captureLog;"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)
        // register the bridge script that listens for the output
        webView.configuration.userContentController.add(self, name: "logHandler")
        
        // add custom value to userAgent to identify iOS WebView environment
        webView.evaluateJavaScript("navigator.userAgent") { [weak webView] (result, error) in
            if let webView = webView, let userAgent = result as? String {
                webView.customUserAgent = userAgent + "/iOS_WebView"
            }
        }
    }

    // When JavaScript code sends a message targets message handler, WebKit calls userContentController
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        // send event
        if message.name == "event" {
            let messageBody = message.body as? String
            let eventName = messageBody?.components(separatedBy: "+")[0]
            let eventValue = messageBody?.components(separatedBy: "+")[1]
            recordEvent(eventName: eventName!, eventValue: eventValue!)
        }
        
        // check and print Console.log
        if message.name == "logHandler" {
            print("LOG: \(message.body)")
        }
    }
    
    // to report event to AppsFlyer 
    func recordEvent(eventName: String, eventValue: String) {
        var eventValueDict = [String: String]()
        let eventValuesData = eventValue.data(using: String.Encoding.utf8)
        do {
            eventValueDict = try (JSONSerialization.jsonObject(with: eventValuesData!, options:[]) as? [String: String])!
        } catch let error as NSError{
            print(error)
        }
        
        AppsFlyerLib.shared().logEvent((eventName as String?)!, withValues: eventValueDict)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
