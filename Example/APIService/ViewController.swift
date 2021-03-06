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

        getHomeBannerData()
    }

    private func getHomeBannerData() {
        let request = CSAPIRequest(path: "/config/homeBanner", dataType: HomeBanner.self)

        APIService.sendRequest(request) { reponse in
            switch reponse.result.validateResult {
            case let .success(info, _):
                print(info)
            case let .failure(_, error):
                print(error)
            }
        }
    }
}


