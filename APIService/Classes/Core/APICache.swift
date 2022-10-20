//
//  APICache.swift
//  CSAPIService
//
//  Created by CoderStar on 2022/9/6.
//

import Foundation

/// 缓存使用模式
public enum APICacheUsageMode {
    /// 不使用缓存
    case none

    /// 命中缓存后，仍然发起网络请求，但是不会执行网络回调
    /// 使用场景：命中缓存后业务方使用缓存，并请求网络刷新缓存
    case alsoNetwork

    /// 命中缓存之后，仍然发起网络请求并执行网络回调
    case alsoNetworkWithCallback

    /// 取消网络请求
    case cancelNetwork
}

/// 缓存写入模式
public enum APICacheWriteMode {
    /// 不缓存
    case none

    /// 内存缓存
    case memory

    /// 磁盘缓存
    case disk

    /// 内存、磁盘两级缓存
    case memoryAndDisk
}

/// 缓存过期策略
public enum APICacheExpiry {
    /// 永不过期
    case never

    /// 指定有效期
    case seconds(TimeInterval)

    /// 指定日期
    case date(Date)
}

/// 缓存
public struct APICache {
    public init() {}

    /// 缓存使用模式
    public var usageMode: APICacheUsageMode = .none

    /// 写入缓存模式
    public var writeNode: APICacheWriteMode = .none

    /// 只有 writeNode 不为 .none 时，后面参数有效

    /// 缓存过期策略类型
    public var expiry: APICacheExpiry = .seconds(0)

    /// 额外的缓存key部分
    /// 可添加app版本号、用户id、缓存版本等
    public var extraCacheKey = ""

    /// 自定义缓存key
    /// 闭包参数为框架内部按照规则生成的key值
    public var customCacheKeyHandler: ((String) -> String)?
}

/// 缓存
public struct APICachePackage: Codable {
    /// 缓存创建时间
    public var creationDate: Date

    /// 缓存数据
    public var data: Data
}

public protocol APICacheTool {
    // MARK: - 异步

    func set(forKey key: String, data: APICachePackage, writeMode: APICacheWriteMode, expiry: APICacheExpiry, completion: ((Result<Void, Error>) -> Void)?)

    /// 如果缓存找不到，缓存过期都走错误分支
    /// 使用 APICacheError
    func getValidObject(byKey key: String, completion: @escaping (Result<APICachePackage, Error>) -> Void)

    // MARK: - 同步

    func set(forKey key: String, data: APICachePackage, writeMode: APICacheWriteMode, expiry: APICacheExpiry) throws

    /// 如果缓存找不到、缓存过期都扔出错误
    /// 使用 APICacheError
    func getValidObject(byKey key: String) throws -> APICachePackage
}
