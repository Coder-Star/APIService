//
//  API+Alamofire.swift
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
public typealias APIDataResponse = AFDataResponse
/// APIDownloadResponse
public typealias APIDownloadResponse = AFDownloadResponse
/// APIRequestAdapter
public typealias APIRequestAdapter = RequestAdapter
/// APIDownloadDestination
public typealias APIDownloadDestination = DownloadRequest.Destination

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

/// APIDataResponseCompletionHandler
public typealias APIDataResponseCompletionHandler = (APIDataResponse<Data>) -> Void
/// APIDownloadResponseCompletionHandler
public typealias APIDownloadResponseCompletionHandler = (APIDownloadResponse<Data>) -> Void

extension Request: APIRequestTask {}

// MARK: - AlamofireAPIClient

struct AlamofireAPIClient: APIClient {
    let sessionManager: Session = {
        let sessionManager = Session(configuration: APIConfig.shared.urlSessionConfiguration, startRequestsImmediately: false)
        return sessionManager
    }()

    func createDataRequest(
        request: URLRequest,
        queue: DispatchQueue,
        progressHandler: APIProgressHandler?,
        completionHandler: @escaping APIDataResponseCompletionHandler
    ) -> APIRequestTask {
        let request = sessionManager.request(request).validate().responseData(queue: queue) { response in
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
        queue: DispatchQueue,
        progressHandler: APIProgressHandler?,
        completionHandler: @escaping APIDownloadResponseCompletionHandler
    ) -> APIRequestTask {
        let request = sessionManager.download(request, to: to).validate().responseData(queue: queue) { response in
            completionHandler(response)
        }
        if let tempProgressHandler = progressHandler {
            request.downloadProgress(closure: tempProgressHandler)
        }
        return request
    }
    
    func createUploadRequest(
        request: URLRequest,
        file: APIFile,
        queue: DispatchQueue,
        progressHandler: APIProgressHandler?,
        completionHandler: @escaping APIDataResponseCompletionHandler
    ) -> any APIRequestTask {
        let request = sessionManager.upload(multipartFormData: { formData in
            formData.append(file.data, withName: file.name, fileName: file.name, mimeType: file.mimeType)
        }, with: request).validate().responseData(queue: queue) { response in
            completionHandler(response)
        }
        if let tempProgressHandler = progressHandler {
            request.downloadProgress(closure: tempProgressHandler)
        }
        return request
    }
}
