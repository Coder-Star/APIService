//
//  HomeBanner.swift
//  APIService_Example
//
//  Created by CoderStar on 2022/5/6.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import APIService
import BetterCodable

struct HomeBanner: APIDefaultJSONParsable {
    var interval: Int

    @DefaultCodable<DefaultEmptyString>
    var info: String

    @DefaultCodable<DefaultEmptyArray>
    var imageList: [ImageList]
}

struct ImageList: Decodable {
    var imgUrl: String
    var actionUrl: String
}
