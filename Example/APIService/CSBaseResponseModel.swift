//
//  DescBaseResponseModel.swift
//  LTXiOSUtilsDemo
//
//  Created by CoderStar on 2022/3/16.
//

import APIService
import Foundation

public struct CSBaseResponseModel<T>: APIModelWrapper, APIDefaultJSONParsable where T: APIDefaultJSONParsable {
    public var code: Int
    public var msg: String
    public var data: T?
}

extension CSBaseResponseModel {
    enum CodingKeys: String, CodingKey {
        case code
        case msg = "desc"
        case data
    }
}
