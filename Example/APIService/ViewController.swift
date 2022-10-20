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
import SVProgressHUD
import UIKit

class ViewController: UIViewController {
    lazy var networkActivityPlugin: NetworkActivityPlugin = {
        let networkActivityPlugin = NetworkActivityPlugin { change in
            switch change {
            case .began:
                SVProgressHUD.show()
            case .ended:
                SVProgressHUD.dismiss()
            }
        }
        return networkActivityPlugin
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "首页"

        let rightBarButtonItem = UIBarButtonItem(title: "请求", style: .plain, target: self, action: #selector(getHomeBannerData))
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }

    @objc
    private func getHomeBannerData() {
        let request = HomeBannerAPI.HomeBannerRequest()

//        APIService.sendRequest(request, plugins: [networkActivityPlugin], cacheHandler: { response in
//            debugPrint(response)
//            if response.result.isSuccess {
//                SVProgressHUD.showInfo(withStatus: "缓存")
//            }
//        }, completionHandler: { response in
//            switch response.result.validateResult {
//            case let .success(info, _):
//                SVProgressHUD.showInfo(withStatus: "网络结果")
//                debugPrint(info)
//            case let .failure(_, error):
//                debugPrint(error)
//            }
//        })

        APIService.sendRequest(request, plugins: [networkActivityPlugin]) { response, type in
            switch type {
            case .network:
                switch response.result.validateResult {
                case let .success(info, _):
                    SVProgressHUD.showInfo(withStatus: "网络结果")
                    debugPrint(info)
                case let .failure(_, error):
                    debugPrint(error)
                }
            case .cache:
                debugPrint(response)
                if response.result.isSuccess {
                    SVProgressHUD.showInfo(withStatus: "缓存")
                }
            }
        }
    }
}
