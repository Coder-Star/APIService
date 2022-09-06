//
//  ViewController.swift
//  APIService
//
//  Created by CoderStar on 04/09/2022.
//  Copyright (c) 2022 CoderStar. All rights reserved.
//

import APIService
import BetterCodable
import Foundation
import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "首页"

        let rightBarButtonItem = UIBarButtonItem(title: "请求", style: .plain, target: self, action: #selector(getHomeBannerData))
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }

    @objc
    private func getHomeBannerData() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 100
        APIConfig.shared.urlSessionConfiguration = configuration
        let request = CSAPIRequest(path: "/config/homeBanner", dataType: HomeBanner.self)

        APIService.sendRequest(request) { response in
            switch response.result.validateResult {
            case let .success(info, _):
                print(info)
            case let .failure(_, error):
                print(error)
            }
        }
    }
}


