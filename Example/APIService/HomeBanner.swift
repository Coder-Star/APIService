//
//  HomeBanner.swift
//  APIService_Example
//
//  Created by CoderStar on 2022/5/6.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import APIService
import BetterCodable
import Foundation

struct HomeBanner: APIDefaultJSONParsable {
    @DefaultIntZero
    var interval: Int

    @DefaultEmptyString
    var info: String

    @DefaultEmptyArray
    var imageList: [ImageList]
}

struct ImageList: Decodable {
    @DefaultEmptyString
    var imgUrl: String

    @DefaultEmptyString
    var actionUrl: String
}

struct LaunchAd: APIDefaultJSONParsable {
    @DefaultEmptyString
    var actionUrl: String = ""

    @DefaultIntZero
    var animationType: Int = 0

    @DefaultIntZero
    var duration: Int = 0

    @DefaultEmptyString
    var imgUrl: String = ""

    @DefaultIntZero
    var skipBtnType: Int = 0
}
