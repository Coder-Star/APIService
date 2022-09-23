//
//  APIConfig.swift
//  CSAPIService
//
//  Created by CoderStar on 2022/9/6.
//

import Foundation

public final class APIConfig {
    private init() {}

    public static let shared = APIConfig()

    // MARK: - 调试

    public var debugLogEnabled = false

    // MARK: - 网络

    /// URLSessionConfiguration
    /// 一次性赋值，有效时机在没有发任何请求之前
    public var urlSessionConfiguration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        return configuration
    }()

    // MARK: - 缓存

    public var cacheTool: APICacheTool?

    /// 默认插件
    public var defaultPlugins: [APIPlugin] = []
}
