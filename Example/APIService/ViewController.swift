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
        let request = DefaultAPIRequest(csPath: "/config/homeBanner", dataType: HomeBanner.self)

        APIService.sendRequest(request) { reponse in
            print(reponse.result)

            switch reponse.result.validateResult {
            case let .success(info, _):
                print(info)
            case let .failure(_, error):
                print(error)
            }
        }
    }
}

public enum APIValidateResult<T> {
    case success(T, String)
    case failure(String, APIError)
}

public enum CSDataError: Error {
    case invalidParseResponse
}

extension APIResult where T: APIModelWrapper {
    var validateResult: APIValidateResult<T.DataType> {
        var message = "出现错误，请稍后重试"
        switch self {
        case let .success(reponse):
            if reponse.code == 200, reponse.data != nil {
                return .success(reponse.data!, reponse.msg)
            } else {
                return .failure(message, APIError.responseError(APIResponseError.invalidParseResponse(CSDataError.invalidParseResponse)))
            }
        case let .failure(apiError):
            if apiError == APIError.networkError {
                message = apiError.localizedDescription
            }

            assertionFailure(apiError.localizedDescription)
            return .failure(message, apiError)
        }
    }
}

struct HomeBanner: APIDefaultJSONParsable {
    var interval: Int

    @DefaultCodable<DefaultEmptyString>
    var info: String

    @DefaultCodable<DefaultEmptyArray>
    var imageList: [ImageList]
}

struct ImageList: Decodable {
    var imgUrl: String
    var actionUrl: String
}

public struct DefaultEmptyString: DefaultCodableStrategy {
    public static var defaultValue: String { "" }
}

public struct DefaultEmptyArray<T>: DefaultCodableStrategy where T: Decodable {
    public static var defaultValue: [T] { [] }
}

public struct DefaultEmptyDict<K, V>: DefaultCodableStrategy where K: Hashable & Codable, V: Codable {
    public static var defaultValue: [K: V] { [:] }
}
