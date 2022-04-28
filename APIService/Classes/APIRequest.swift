//
//  APIRequest.swift
//  LTXiOSUtils
//
//  Created by CoderStar on 2022/3/4.
//

import Foundation

/// 任务类型
public enum APIRequestTaskType {
    /// 请求
    case request
    /// 上传
    case upload
    /// 下载
    case download
}

// MARK: - 请求协议

/// 请求协议
/// 每一个域名一个
public protocol APIRequest {
    /// 回调实体
    associatedtype Response: APIParsable

    /// 基础地址
    var baseURL: URL { get }

    /// 接口路径
    var path: String { get }

    /// 方法
    var method: APIRequestMethod { get }

    /// 参数
    var parameters: [String: Any]? { get }

    /// header
    var headers: APIRequestHeaders? { get }

    /// 任务类型
    var taskType: APIRequestTaskType { get }

    /// 参数编码处理
    var encoding: APIParameterEncoding { get }

    /// 拦截urlRequest，在传给client之前
    /// 对其加上额外的统一参数，比如token等
    ///
    /// - Parameter urlRequest: 已经构造的 URLRequest
    /// - Returns: 处理之后的 URLRequest
    func intercept(urlRequest: URLRequest) throws -> URLRequest

    /// 拦截回调，在回调给接收方之前
    ///
    /// - Parameter request: 发送的URLRequest
    /// - Parameter response: 回调结果
    /// - Parameter replaceCompletionHandler: 替换返回给业务方的回调，如果不处理，将 response 回调即可
    /// - Returns: 处理之后的 URLRequest
    func intercept<U: APIRequest>(request: U, response: APIResponse<Response>, replaceResponseHandler: @escaping APICompletionHandler<Response>)
}

// MARK: - 默认实现

extension APIRequest {
    public func intercept(urlRequest: URLRequest) throws -> URLRequest {
        return urlRequest
    }

    public func intercept<U: APIRequest>(request: U, response: APIResponse<Response>, replaceResponseHandler: @escaping APICompletionHandler<Response>) {
        replaceResponseHandler(response)
    }
}

extension APIRequest {
    /// 完整的URL
    var completeURL: URL {
        return path.isEmpty ? baseURL : baseURL.appendingPathComponent(path)
    }

    /// 根据相关信息构造URLRequest
    func buildURLRequest(encoding: APIParameterEncoding?) throws -> URLRequest {
        do {
            let originalRequest = try URLRequest(url: completeURL, method: method, headers: headers)
            /// 优先使用单个API的编码方式，其次使用Request级别的编码方式
            let encodedURLRequest = try (encoding ?? self.encoding).encode(originalRequest, with: parameters)
            return try intercept(urlRequest: encodedURLRequest)
        } catch {
            throw APIRequestError.invalidURLRequest
        }
    }
}


