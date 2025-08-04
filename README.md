
# 🍏 AppsFlyer iOS WebView Sample App

This repository demonstrates how to **send in-app events from a WebView inside an iOS hybrid app** using the [AppsFlyer iOS SDK](https://support.appsflyer.com/hc/en-us/articles/207032066-Basic-SDK-integration-guide) and prevent duplicate reporting when used together with the [PBA Web SDK](https://support.appsflyer.com/hc/en-us/articles/360001610038-PBA-Web-SDK-integration-guide).

It supports two methods of integrating WebView in-app event tracking:

- **JavaScript messaging via `WKScriptMessageHandler`**
- **URL scheme interception via `WKNavigationDelegate`**

---

## 🔧 Prerequisites

- Read: [In-app events for hybrid apps — AppsFlyer Support](https://support.appsflyer.com/hc/en-us/articles/207031976-In-app-events-for-hybrid-apps)
- Integrate the [AppsFlyer iOS SDK](https://support.appsflyer.com/hc/en-us/articles/207032066-Basic-SDK-integration-guide#starting-the-sdk-in-ios)
- Use `WKWebView` in a hybrid app environment
- WebView HTML samples:  
  https://github.com/AppsFlyerSDK/webview-http-sample-page

---

## 📁 File Overview

| File / Class | Description |
|--------------|-------------|
| `ViewController.swift` | Entry point that lets users choose between the JS messaging and URL loading WebView demo |
| `JSWebViewController.swift` | Demonstrates how to inject `WKUserScript` and use `WKScriptMessageHandler` to receive events from JavaScript and forward them to the AppsFlyer SDK |
| `URLViewController.swift` | Demonstrates how to intercept `af-event://` custom URL scheme using `WKNavigationDelegate` and send in-app events to the SDK |
---

## ⚙️ Runtime Behavior

### JavaScript Messaging (`JSWebViewController.swift` with `jsinterface.html`)

- A `WKUserScript` is injected into the WebView, and a `WKScriptMessageHandler` listens for calls from JavaScript:

```swift
userContentController.add(self, name: "event")
```

- JavaScript on the page calls:

```js
webkit.messageHandlers.event.postMessage(...)
```

- The native handler in `JSWebViewController` logs the event with:

```swift
AppsFlyerLib.shared().logEvent(eventName as String?, withValues: eventValueDict)
```

- The PBA Web SDK is **not initialized** if `window.webkit.messageHandlers.event` is detected.

---

### URL Loading Interception (`URLViewController.swift` with `urlloading.html`)

- The WebView loads a page that issues a URL like:

```js
iframe.setAttribute("src", "af-event://inappevent?eventName=...&eventValue=...");
```

- This URL is intercepted in the delegate method:

```swift
func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: ...) {
    if let url = navigationAction.request.url, url.scheme == "af-event" {
        // Parse and send to AppsFlyer
    }
}
```

- In addition, the app adds `/iOS_WebView` to the user-agent so that Web SDK logic can skip initialization based on UA string.

---

## ✅ Duplicate Event Prevention

This sample ensures that:

- Events from WebView are sent **only via the iOS native SDK**
- The Web SDK is skipped when either:
  - The presence of `window.webkit.messageHandlers.event` is detected
  - The user agent contains `/iOS_WebView`

This avoids duplicate in-app event reporting when both SDKs are present.

---

## 🧭 In-App Event Propagation Flow

```
┌────────────────────┐
│   In-app event     │
└─────────┬──────────┘
          │
          ▼
┌──────────────────────────────┐
│ WebView with native SDK?     │───────────┐
└──────────┬───────────────────┘           │
           │ Yes                           │ No
           ▼                               ▼
┌──────────────────────┐     ┌──────────────────────────┐
│ JS message or URL    │     │ Initialize PBA Web SDK   │
│ scheme detected      │     └─────────────┬────────────┘
└──────────┬───────────┘                   ▼
           ▼                 ┌──────────────────────────┐
┌──────────────────────┐     │ Track event with         │
│ iOS SDK receives     │     │ Web SDK                  │
└──────────┬───────────┘     └─────────────┬────────────┘
           ▼                               ▼
┌──────────────────────┐     ┌──────────────────────────┐
│ Send in-app event to │     │ Send in-app event to     │
│ AppsFlyer            │     │ AppsFlyer                │
└──────────────────────┘     └──────────────────────────┘
```

---

## 📎 Related Docs

- [iOS SDK Integration Guide](https://dev.appsflyer.com/hc/docs/ios-sdk)  
- [In-App Events in Hybrid Apps](https://support.appsflyer.com/hc/en-us/articles/207031976-In-app-events-for-hybrid-apps)  
- [PBA Web SDK Integration Guide](https://support.appsflyer.com/hc/en-us/articles/360001610038-PBA-Web-SDK-integration-guide)
