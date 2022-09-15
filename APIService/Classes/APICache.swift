//
//  APICache.swift
//  CSAPIService
//
//  Created by CoderStar on 2022/9/6.
//

import Foundation

public struct APICacheMetaData {
    /// 版本
    var version: Int

    /// 缓存创建时间
    var creationDate: Date
}

public enum APICacheValidType {
    /// 没有缓存，默认值
    case `default`

    /// 永不过期
    case neverExpire

    /// 根据时间过期
    /// 单位：秒
    case time(second: TimeInterval)
}

public protocol APICache {
    var validType: APICacheValidType { get }

    /// 缓存版本
    /// 当后台结构发生变化时，修改版本来使历史结构缓存失效
    var cacheVersion: Int { get }

    /// 是否异步写入缓存
    var writeCacheAsynchronously: Bool { get }
}

public protocol APICacheStore {
    func saveCache(data: Data, metaData: APICacheMetaData) -> String

    func removeCache(key: String)

    func getCache(key: String) -> (data: Data, metaData: APICacheMetaData)
}

extension APICacheStore {
    func saveCache(data: Data, metaData: APICacheMetaData) -> String {
        return String(data: data, encoding: .utf8) ?? ""
    }

    func removeCache(key: String) {

    }

    func getCache(key: String) -> (data: Data, metaData: APICacheMetaData) {
        return (key.data(using: .utf8)!, APICacheMetaData(version: 0, creationDate: Date()))
    }
}
