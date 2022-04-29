//
//  API+Alamofireswift.swift
//  LTXiOSUtils
//
//  Created by CoderStar on 2022/3/24.
//

import Alamofire
import Foundation

// MARK: - 别名

public typealias APIRequestMethod = HTTPMethod
public typealias APIRequestHeaders = HTTPHeaders
public typealias APIDataResponse = DataResponse
public typealias APIDownloadResponse = DownloadResponse
public typealias APIRequestAdapter = RequestAdapter
public typealias APIDownloadDestination = DownloadRequest.DownloadFileDestination

public typealias APIMultipartFormData = MultipartFormData
public typealias APIParameterEncoding = ParameterEncoding
public typealias APIJSONEncoding = JSONEncoding
public typealias APIURLEncoding = URLEncoding
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
