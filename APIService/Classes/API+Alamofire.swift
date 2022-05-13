//
//  API+Alamofireswift.swift
//  LTXiOSUtils
//
//  Created by CoderStar on 2022/3/24.
//

import Alamofire
import Foundation

// MARK: - 别名

/// Method
public typealias APIRequestMethod = HTTPMethod
/// Header
public typealias APIRequestHeaders = HTTPHeaders
/// APIDataResponse
public typealias APIDataResponse = DataResponse
/// APIDownloadResponse
public typealias APIDownloadResponse = DownloadResponse
/// APIRequestAdapter
public typealias APIRequestAdapter = RequestAdapter
/// APIDownloadDestination
public typealias APIDownloadDestination = DownloadRequest.DownloadFileDestination

/// APIMultipartFormData
public typealias APIMultipartFormData = MultipartFormData
/// APIParameterEncoding
public typealias APIParameterEncoding = ParameterEncoding
/// APIJSONEncoding
public typealias APIJSONEncoding = JSONEncoding
/// APIURLEncoding
public typealias APIURLEncoding = URLEncoding
/// APINetworkReachabilityManager
public typealias APINetworkReachabilityManager = NetworkReachabilityManager

extension Request: APIRequestTask {}

// MARK: - AlamofireAPIClient

struct AlamofireAPIClient: APIClient {
    let sessionManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        let sessionManager = SessionManager(configuration: configuration)
        sessionManager.startRequestsImmediately = false
        return sessionManager
    }()

    func createDataRequest(
        request: URLRequest,
        progressHandler: APIProgressHandler?,
        completionHandler: @escaping APIDataResponseCompletionHandler
    ) -> APIRequestTask {
        let request = sessionManager.request(request).validate().responseData { response in
            completionHandler(response)
        }
        if let tempProgressHandler = progressHandler {
            request.downloadProgress(closure: tempProgressHandler)
        }
        return request
    }

    func createDownloadRequest(
        request: URLRequest,
        to: @escaping APIDownloadDestination,
        progressHandler: APIProgressHandler?,
        completionHandler: @escaping APIDownloadResponseCompletionHandler
    ) -> APIRequestTask {
        let request = sessionManager.download(request, to: to).validate().responseData { response in
            completionHandler(response)
        }
        if let tempProgressHandler = progressHandler {
            request.downloadProgress(closure: tempProgressHandler)
        }
        return request
    }
}
