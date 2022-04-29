//
//  DefaultAPIRequestExtension.swift
//  APIService_Example
//
//  Created by CoderStar on 2022/4/29.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import APIService

extension DefaultAPIRequest {
    public init<S>(csPath: String, dataType: S.Type) where CSBaseResponseModel<S> == T {
        self.init(baseURL: NetworkConstants.baseURL, path: csPath, dataType: dataType)
    }

    public init(csPath: String, responseType: Response.Type) {
        self.init(baseURL: NetworkConstants.baseURL, path: csPath, responseType: responseType)
    }
}
