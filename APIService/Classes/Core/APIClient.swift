//
//  APIClient.swift
//  LTXiOSUtils
//
//  Created by CoderStar on 2022/3/4.
//

import Foundation

/// APIProgressHandler
public typealias APIProgressHandler = (Progress) -> Void

/// 网络请求任务协议
public protocol APIRequestTask {
    /// 恢复
    @discardableResult
    func resume() -> Self

    /// 取消
    @discardableResult
    func cancel() -> Self
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
        queue: DispatchQueue,
        progressHandler: APIProgressHandler?,
        completionHandler: @escaping APIDataResponseCompletionHandler
    ) -> APIRequestTask

    /// 创建下载请求
    ///
    /// - Parameters:
    ///   - request: 请求
    ///   - to: 设置下载的地址以及配置
    ///   - progressHandler: 进度回调
    ///   - completionHandler: 结果回调
    /// - Returns: 请求任务
    func createDownloadRequest(
        request: URLRequest,
        to: @escaping APIDownloadDestination,
        queue: DispatchQueue,
        progressHandler: APIProgressHandler?,
        completionHandler: @escaping APIDownloadResponseCompletionHandler
    ) -> APIRequestTask
}
