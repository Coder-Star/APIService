//
//  APIConfig.swift
//  CSAPIService
//
//  Created by CoderStar on 2022/9/6.
//

import Foundation

public class APIConfig {
    private init() {}

    public static let shared = APIConfig()

    /// URLSessionConfiguration
    /// 一次性赋值，有效时机在没有发任何请求之前
    public var urlSessionConfiguration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        return configuration
    }()

    public var debugLogEnabled = false
}
