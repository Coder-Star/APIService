//
//  BetterCodableExtensions.swift
//  APIService_Example
//
//  Created by CoderStar on 2022/5/6.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import Foundation
import BetterCodable

public struct DefaultEmptyString: DefaultCodableStrategy {
    public static var defaultValue: String { "" }
}

public struct DefaultEmptyArray<T>: DefaultCodableStrategy where T: Decodable {
    public static var defaultValue: [T] { [] }
}

public struct DefaultEmptyDict<K, V>: DefaultCodableStrategy where K: Hashable & Codable, V: Codable {
    public static var defaultValue: [K: V] { [:] }
}
