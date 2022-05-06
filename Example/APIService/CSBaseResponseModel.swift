//
//  DescBaseResponseModel.swift
//  LTXiOSUtilsDemo
//
//  Created by CoderStar on 2022/3/16.
//

import Foundation
import APIService

public struct CSBaseResponseModel<T>: APIModelWrapper, APIDefaultJSONParsable where T: Decodable {
    public var code: Int
    public var msg: String
    public var data: T?

    enum CodingKeys: String, CodingKey {
        case code
        case msg = "desc"
        case data
    }
}




