//
//  APIPlugin.swift
//  LTXiOSUtils
//
//  Created by CoderStar on 2022/3/26.
//

import Foundation

/// 插件
public protocol APIPlugin {
    /// 构造URLRequest
    /// 单个API的超时时间可在此进行设置
    func prepare<T: APIRequest>(_ request: URLRequest, targetRequest: T) -> URLRequest

    /// 发送之前
    /// 返回值控制是否允许发送，true：允许发送（默认值），false：不允许发送
    func willSend<T: APIRequest>(_ request: URLRequest, targetRequest: T) -> Bool

    /// 接收结果，时机在返回给调用方之前
    func willReceive<T: APIRequest>(_ result: APIResponse<T.Response>, targetRequest: T)

    /// 接收结果，时机在返回给调用方之后
    func didReceive<T: APIRequest>(_ result: APIResponse<T.Response>, targetRequest: T)
}

// MARK: - 默认实现

extension APIPlugin {
    public func prepare<T: APIRequest>(_ request: URLRequest, targetRequest: T) -> URLRequest { request }

    public func willSend<T: APIRequest>(_ request: URLRequest, targetRequest: T) -> Bool {
        return true
    }

    public func willReceive<T: APIRequest>(_ result: APIResponse<T.Response>, targetRequest: T) { }

    public func didReceive<T: APIRequest>(_ result: APIResponse<T.Response>, targetRequest: T) {}
}
