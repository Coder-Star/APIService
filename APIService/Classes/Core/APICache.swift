//
//  APICache.swift
//  CSAPIService
//
//  Created by CoderStar on 2022/9/6.
//

import Foundation

public enum APICacheReadMode {
    /// 不使用缓存
    case none

    /// 命中缓存之后仍然发起网络请求
    case alsoNetwork

    /// 取消网络请求
    case cancelNetwork
}

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

public struct APICache {
    public init() { }

    /// 读取缓存模式
    public var readMode: APICacheReadMode = .none

    /// 写入缓存模式
    public var writeNode: APICacheWriteMode = .none

    /// 只有 writeNode 不为 .none 时，后面参数有效

    /// 额外的缓存key部分
    /// 可添加app版本号、用户id、缓存版本等
    public var extraCacheKey = ""

    /// 是否允许缓存
    /// 可根据业务实际情况控制
    public var shouldCacheHandler: ((HTTPURLResponse?, Data?) -> Bool)?

    /// 自定义缓存key
    public var customCacheKeyHandler: ((String) -> String)?

    /// 缓存策略类型
    public var expiry: APICacheExpiry = .seconds(0)
}

public struct APICachePackage: Codable {
    /// 缓存创建时间
    public var creationDate: Date

    /// 缓存数据
    public var data: Data
}

public enum APICacheExpiry {
    /// 永不过期
    case never

    /// 指定有效期
    case seconds(TimeInterval)

    /// 指定日期前
    case date(Date)
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
