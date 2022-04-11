//
//  APIClient.swift
//  LTXiOSUtils
//
//  Created by CoderStar on 2022/3/4.
//

import Foundation

public typealias APIDataResponseCompletionHandler = (APIDataResponse<Data>) -> Void
public typealias APIProgressHandler = (Progress) -> Void

public typealias APIRequestTask = APICancellable

/// 网络请求任务协议
public protocol APICancellable {
    /// 取消
    func cancel()
}

/// 网络请求客户端协议
public protocol APIClient {
    /// 创建数据请求
    ///
    /// - Parameters:
    ///   - request: 请求
    ///   - progressHandler: 进度回调
    ///   - completionHandler: 结果回调
    /// - Returns: 请求任务
    func createDataRequest(
        request: URLRequest,
        progressHandler: APIProgressHandler?,
        completionHandler: @escaping APIDataResponseCompletionHandler
    ) -> APIRequestTask
}
