//
//  HomeBannerAPI.swift
//  APIService_Example
//
//  Created by CoderStar on 2022/9/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import APIService

enum HomeBannerAPI {
    struct HomeBannerRequest: CSAPIRequest {
        typealias DataResponse = HomeBanner

        var parameters: [String: Any]? {
            return nil
        }

        var path: String {
            return "/config/homeBanner"
        }

        var cache: APICache? {
            var cache = APICache()
            cache.readMode = .cancelNetwork
            cache.writeNode = .memoryAndDisk
            cache.expiry = .seconds(10)
            return cache
        }

        var cacheShouldWriteHandler: ((APIResponse<CSBaseResponseModel<DataResponse>>) -> Bool)? = { response in
            if response.result.isSuccessCode, response.result.value?.data != nil {
                return true
            }
            return false
        }
    }
}
