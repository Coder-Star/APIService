//
//  HomeBannerAPI.swift
//  APIService_Example
//
//  Created by CoderStar on 2022/9/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation

struct HomeBannerAPI {
    struct HomeBannerRequest: CSAPIRequest {
        typealias DataResponse = HomeBanner

        var parameters: [String: Any]? {
            return nil
        }

        var path: String {
            return "/config/homeBanner"
        }
    }
}
