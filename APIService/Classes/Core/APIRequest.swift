//
//  APIRequest.swift
//  LTXiOSUtils
//
//  Created by CoderStar on 2022/3/4.
//

import Foundation
import CommonCrypto

public struct APIFile {
    public var name: String
    public var data: Data
    public var fileName: String
    public var mimeType: String
    
    public init(name: String, data: Data, fileName: String, mimeType: String) {
        self.name = name
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }
}

/// 任务类型
public enum APIRequestTaskType {
    /// 请求
    case request
    
    /// 下载
    case download(APIDownloadDestination)
    
    /// 上传
    /// 表单方式
    case upload(APIFile)
}

// MARK: - 请求协议

/// 请求协议
/// 每一个域名一个
public protocol APIRequest {
    // MARK: - 回调实体

    /// 回调实体
    associatedtype Response: APIParsable

    // MARK: - 请求

    /// 基础地址
    var baseURL: URL { get }

    /// 接口路径
    var path: String { get }
    
    /// 完整地址，当不为nil的时候优先使用这个
    /// 其等于 baseURL + path
    var url: URL? { get }

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

    // MARK: - 缓存相关

    /// 缓存
    /// 目前 taskType 为 request 才生效
    var cache: APICache? { get }

    /// 是否允许缓存
    /// 可根据业务实际情况控制：比如业务code为成功，业务数据不为空
    /// 这个闭包之所以不放入 APICache 内部的原因是 享受泛型的回调
    var cacheShouldWriteHandler: ((APIResponse<Response>) -> Bool)? { get }

    /// 过滤不参与缓存key生成的参数
    /// 如果一些业务场景不想统一参数参与缓存key生成，可在此配置
    var cacheFilterParameters: [String] { get }

    // MARK: - 方法

    /// 拦截参数，在参数编码之前
    /// 可以用于加上一些统一参数的场景
    /// 参数的相关操作最好都在这个位置进行处理，缓存key依赖于这个参数
    ///
    /// - Parameter parameters: 业务方传入的参数
    /// - Returns: 处理后的参数
    func intercept(parameters: [String: Any]?) -> [String: Any]?

    /// 拦截urlRequest，在传给client之前
    /// 可以用于添加统一Header等场景
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
    public var url: URL? {
        return nil
    }
    
    public var cache: APICache? {
        return nil
    }

    public var cacheShouldWriteHandler: ((APIResponse<Response>) -> Bool)? {
        return nil
    }

    public var cacheFilterParameters: [String] {
        return []
    }

    public func intercept(parameters: [String: Any]?) -> [String: Any]? {
        return parameters
    }

    public func intercept(urlRequest: URLRequest) throws -> URLRequest {
        return urlRequest
    }

    public func intercept<U: APIRequest>(request: U, response: APIResponse<Response>, replaceResponseHandler: @escaping APICompletionHandler<Response>) {
        replaceResponseHandler(response)
    }
}

extension APIRequest {
    /// 完整的URL
    /// 不包含参数，只是 baseURL 与 path 的拼接
    public var completeURL: URL {
        if let url = url {
            return url
        }
        return path.isEmpty ? baseURL : baseURL.appendingPathComponent(path)
    }

    /// 最终的参数
    var resultParameters: [String: Any]? {
        return intercept(parameters: parameters)
    }

    /// 根据相关信息构造URLRequest
    func buildURLRequest() throws -> URLRequest {
        do {
            let originalRequest = try URLRequest(url: completeURL, method: method, headers: headers)
            let encodedURLRequest = try encoding.encode(originalRequest, with: resultParameters)
            return try intercept(urlRequest: encodedURLRequest)
        } catch {
            throw APIRequestError.invalidURLRequest
        }
    }
}

// MARK: - 缓存相关

extension APIRequest {
    /// 缓存key
    var cacheKey: String {
        /// 参数字符串
        var paramString = ""
        if var resultParameters = resultParameters, !resultParameters.isEmpty {
            resultParameters = resultParameters.filter { !cacheFilterParameters.contains($0.key) }
            let paramKeys = resultParameters.keys.sorted()
            paramKeys.forEach {
                let value = resultParameters[$0] ?? ""
                paramString.append(contentsOf: "\(paramString.isEmpty ? "?" : "&")\($0)=\(value)")
            }
        }

        var cacheKey = "\(method.rawValue)-\(completeURL.absoluteString)\(paramString)"
        if let extraCacheKey = cache?.extraCacheKey, !extraCacheKey.isEmpty {
            cacheKey.append(contentsOf: "-\(extraCacheKey)")
        }

        if let customCacheKeyHandler = cache?.customCacheKeyHandler {
            return customCacheKeyHandler(cacheKey)
        }

        return cacheKey.md5
    }
}

extension String {
    /// md5
    fileprivate var md5: String {
        guard let data = data(using: .utf8) else {
            return self
        }
        var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))

        _ = data.withUnsafeBytes { buffer in
            CC_MD5(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }

        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
