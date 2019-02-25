//
//  InfoPageController.swift
//  EncryptionBenchmark
//
//  Created by Andrey Filonov on 06/06/2018.
//  Copyright © 2018 Andrey Filonov. All rights reserved.
//

import UIKit
import WebKit

class HelpPageController: UIViewController, WKNavigationDelegate {
    
    var webView: WKWebView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    var disableNavControllerGestureForInfoPage = false
    var helpPageName = "benchmark"
    
    
    @IBAction func dismissButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(patternImage: UIImage(named: "bright-squares")!)
        setupWebView()
        loadWebPage()
    }
    
    
    private func setupWebView() {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isOpaque = false //prevents white blank page
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }
    
    
    func loadWebPage() {
        guard let url = Bundle.main.url(forResource: helpPageName, withExtension: "html")
            else {
                print("Error getting url")
                return
        }
        webView.loadFileURL(url, allowingReadAccessTo: url)
        webView.allowsBackForwardNavigationGestures = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = !webView.canGoBack
        self.disableNavControllerGestureForInfoPage = webView.canGoBack
    }
}
