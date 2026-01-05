//
//  APIService+Async.swift
//  APIService
//
//  Created by CoderStar on 2024/01/01.
//

import Foundation

// MARK: - Async/Await Support

private enum APIServiceAsyncError: LocalizedError {
    case unsupportedCacheUsageMode

    var errorDescription: String? {
        switch self {
        case .unsupportedCacheUsageMode:
            return "sendRequestAsync 不支持当前缓存模式（alsoNetworkWithCallback）"
        }
    }
}

/// API响应异步序列，支持缓存和网络数据的多次返回
public struct APIResponseAsyncSequence<T>: AsyncSequence {
    public typealias Element = (APIResponse<T>, APICompletionHandlerSourceType)
    
    private let producer: (@escaping (Element) -> Void, @escaping () -> Void) -> Void
    
    internal init(producer: @escaping (@escaping (Element) -> Void, @escaping () -> Void) -> Void) {
        self.producer = producer
    }
    
    public func makeAsyncIterator() -> APIResponseAsyncIterator<T> {
        return APIResponseAsyncIterator(producer: producer)
    }
}

/// API响应异步迭代器
public struct APIResponseAsyncIterator<T>: AsyncIteratorProtocol {
    public typealias Element = (APIResponse<T>, APICompletionHandlerSourceType)
    
    private let producer: (@escaping (Element) -> Void, @escaping () -> Void) -> Void
    private var continuation: AsyncStream<Element>.Continuation?
    private var iterator: AsyncStream<Element>.Iterator?
    private var hasStarted = false
    
    internal init(producer: @escaping (@escaping (Element) -> Void, @escaping () -> Void) -> Void) {
        self.producer = producer
    }
    
    public mutating func next() async -> Element? {
        if !hasStarted {
            hasStarted = true
            let stream = AsyncStream<Element> { continuation in
                self.continuation = continuation
                producer({ element in
                    continuation.yield(element)
                }, {
                    continuation.finish()
                })
            }
            iterator = stream.makeAsyncIterator()
        }
        
        return await iterator?.next()
    }
}

extension APIService {
    /// 异步发送请求
    ///
    /// - Parameters:
    ///   - request: 请求
    ///   - plugins: 插件
    ///   - queue: 回调队列
    ///   - progressHandler: 进度回调
    /// - Returns: 请求结果
    /// - Throws: APIError
    public static func sendRequestAsync<T: APIRequest>(
        _ request: T,
        plugins: [APIPlugin] = [],
        queue: DispatchQueue = .main,
        progressHandler: APIProgressHandler? = nil
    ) async throws -> APIResponse<T.Response> {
        return try await `default`.sendRequestAsync(
            request,
            plugins: plugins,
            queue: queue,
            progressHandler: progressHandler
        )
    }
    
    /// 异步发送请求 - AsyncSequence版本，支持缓存和网络数据的多次返回
    /// 会根据缓存策略返回一个或多个结果
    ///
    /// - Parameters:
    ///   - request: 请求
    ///   - plugins: 插件
    ///   - progressHandler: 进度回调
    /// - Returns: 异步序列，包含数据来源信息
    public static func sendRequestSequence<T: APIRequest>(
        _ request: T,
        plugins: [APIPlugin] = [],
        progressHandler: APIProgressHandler? = nil
    ) -> APIResponseAsyncSequence<T.Response> {
        return `default`.sendRequestSequence(
            request,
            plugins: plugins,
            progressHandler: progressHandler
        )
    }
}

extension APIService {
    /// 异步发送请求
    ///
    /// - Parameters:
    ///   - request: 请求
    ///   - plugins: 插件
    ///   - queue: 回调队列
    ///   - progressHandler: 进度回调
    /// - Returns: 请求结果
    /// - Throws: APIError
    public func sendRequestAsync<T: APIRequest>(
        _ request: T,
        plugins: [APIPlugin] = [],
        queue: DispatchQueue = .main,
        progressHandler: APIProgressHandler? = nil
    ) async throws -> APIResponse<T.Response> {
        if request.cache?.usageMode == .alsoNetworkWithCallback {
            throw APIError.responseError(APIServiceAsyncError.unsupportedCacheUsageMode)
        }

        func unwrap(_ response: APIResponse<T.Response>) throws -> APIResponse<T.Response> {
            switch response.result {
            case .success:
                return response
            case .failure(let error):
                throw error
            }
        }

        var cachedResponse: APIResponse<T.Response>?
        var iterator = sendRequestSequence(
            request,
            plugins: plugins,
            queue: queue,
            progressHandler: progressHandler
        ).makeAsyncIterator()

        while let (response, sourceType) = await iterator.next() {
            if sourceType == .cache {
                cachedResponse = response
                if let cache = request.cache {
                    // cancelNetwork：命中缓存直接返回；alsoNetwork：网络回调被抑制，直接返回缓存
                    if cache.usageMode == .cancelNetwork || cache.usageMode == .alsoNetwork {
                        return try unwrap(response)
                    }
                }
            }

            // 首个网络结果直接返回
            if sourceType == .network {
                return try unwrap(response)
            }
        }

        // 没有网络结果时（例如 alsoNetwork），使用缓存兜底
        if let cachedResponse {
            return try unwrap(cachedResponse)
        }

        throw APIError.networkError
    }
    
    /// 异步发送请求 - 实例方法，AsyncSequence版本
    ///
    /// - Parameters:
    ///   - request: 请求
    ///   - plugins: 插件
    ///   - progressHandler: 进度回调
    /// - Returns: 异步序列
    public func sendRequestSequence<T: APIRequest>(
        _ request: T,
        plugins: [APIPlugin] = [],
        queue: DispatchQueue = .main,
        progressHandler: APIProgressHandler? = nil
    ) -> APIResponseAsyncSequence<T.Response> {
        return APIResponseAsyncSequence { [weak self] yield, finish in
            guard let self = self else { return }
            
            var cacheHit = false
            let usageMode = request.cache?.usageMode
            
            let _ = self.sendRequest(
                request,
                plugins: plugins,
                queue: queue,
                progressHandler: progressHandler,
                cacheHandler: { response in
                    cacheHit = true
                    yield((response, .cache))
                },
                completionHandler: { response in
                    // alsoNetwork 模式：命中缓存后，网络回调被抑制
                    if usageMode == .alsoNetwork && cacheHit {
                        finish()
                        return
                    }
                    yield((response, .network))
                    finish()
                }
            )
        }
    }
}
