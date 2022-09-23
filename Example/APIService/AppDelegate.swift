//
//  AppDelegate.swift
//  APIService
//
//  Created by CoderStar on 04/09/2022.
//  Copyright (c) 2022 CoderStar. All rights reserved.
//

import UIKit
import SVProgressHUD
import APIService

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        initLaunch()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {}
}

extension AppDelegate {
    private func initLaunch() {
        SVProgressHUD.setBackgroundColor(.black.withAlphaComponent(0.8))
        SVProgressHUD.setForegroundColor(.white)
        SVProgressHUD.setMinimumDismissTimeInterval(0.8)
        SVProgressHUD.setMaximumDismissTimeInterval(1.6)
        SVProgressHUD.setMinimumSize(CGSize(width: 100, height: 40))


        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 100
        APIConfig.shared.urlSessionConfiguration = configuration
        APIConfig.shared.cacheTool = CacheTool.shared
        APIConfig.shared.debugLogEnabled = true

        print(NSHomeDirectory())
    }
}
