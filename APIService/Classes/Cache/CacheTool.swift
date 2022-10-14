//
//  DefaultCacheStore.swift
//  CSAPIService
//
//  Created by CoderStar on 2022/9/19.
//

import Cache
import Foundation

/// 默认的缓存工具
public final class CacheTool {
    /// 单例
    public static let shared = CacheTool()

    /// 内存缓存配置
    public var memoryConfig: MemoryConfig?

    /// 磁盘缓存配置
    public var diskConfig: DiskConfig?

    private let defaultMemoryConfig = MemoryConfig()

    /// 默认最大尺寸 50M
    private let defaultDiskConfig = DiskConfig(
        name: "Cache",
        expiry: .never,
        maxSize: 1024 * 1024 * 50,
        directory: try! FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("com.coderstar.APIService"),
        protectionType: .complete
    )

    private var storage: Storage<String, APICachePackage>?

    private var hybridStorage: HybridStorage<String, APICachePackage>?

    private var memoryStorage: MemoryStorage<String, APICachePackage>?

    private var diskStorage: DiskStorage<String, APICachePackage>?

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(clearMemoryCache), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cleanExpiredDiskCache), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(backgroundCleanExpiredDiskCache), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    private func getDiskStorage() throws -> DiskStorage<String, APICachePackage> {
        if let storage = diskStorage {
            return storage
        } else {
            let diskStorage = try DiskStorage<String, APICachePackage>(config: diskConfig ?? defaultDiskConfig, transformer: TransformerFactory.forCodable(ofType: APICachePackage.self))
            self.diskStorage = diskStorage
            return diskStorage
        }
    }

    private func getMemoryStorage() -> MemoryStorage<String, APICachePackage> {
        if let storage = memoryStorage {
            return storage
        } else {
            let memoryStorage = MemoryStorage<String, APICachePackage>(config: memoryConfig ?? defaultMemoryConfig)
            self.memoryStorage = memoryStorage
            return memoryStorage
        }
    }

    private func getStorage() throws -> Storage<String, APICachePackage> {
        if let storage = storage {
            return storage
        } else {
            let memoryStorage = getMemoryStorage()
            let diskStorage = try getDiskStorage()
            let hybridStorage = HybridStorage(memoryStorage: memoryStorage, diskStorage: diskStorage)
            let storage = Storage(hybridStorage: hybridStorage)

            self.hybridStorage = hybridStorage
            self.storage = storage

            return storage
        }
    }

    @objc
    private func clearMemoryCache() {
        self.memoryStorage?.removeAll()
    }

    @objc
    private func cleanExpiredDiskCache() {
        self.storage?.async.removeExpiredObjects { _ in }
    }

    @objc
    private func backgroundCleanExpiredDiskCache() {
        let sharedApplication = UIApplication.shared

        func endBackgroundTask(_ task: inout UIBackgroundTaskIdentifier) {
            sharedApplication.endBackgroundTask(task)
            task = UIBackgroundTaskIdentifier.invalid
        }

        var backgroundTask: UIBackgroundTaskIdentifier!
        backgroundTask = sharedApplication.beginBackgroundTask {
            endBackgroundTask(&backgroundTask!)
        }

        self.storage?.async.removeExpiredObjects { _ in
            endBackgroundTask(&backgroundTask!)
        }
    }
}

extension CacheTool: APICacheTool {
    public func set(forKey key: String, data: APICachePackage, writeMode: APICacheWriteMode, expiry: APICacheExpiry, completion: ((Swift.Result<Void, Error>) -> Void)?) {
        let resultExpiry: Expiry

        switch expiry {
        case .never:
            resultExpiry = .never
        case let .seconds(seconds):
            resultExpiry = .seconds(seconds)
        case let .date(date):
            resultExpiry = .date(date)
        }

        do {
            switch writeMode {
            case .none:
                break
            case .memory:
                getMemoryStorage().setObject(data, forKey: key, expiry: resultExpiry)
            case .disk:
                try getStorage().async.serialQueue.async { [weak self] in
                    guard let self = self else {
                        completion?(.failure(StorageError.deallocated))
                        return
                    }

                    do {
                        try self.getDiskStorage().setObject(data, forKey: key, expiry: resultExpiry)
                        completion?(.success(()))
                    } catch {
                        completion?(.failure(error))
                    }
                }
            case .memoryAndDisk:
                try getStorage().async.setObject(data, forKey: key, expiry: resultExpiry) { result in
                    switch result {
                    case let .value(value):
                        completion?(.success(value))
                    case let .error(error):
                        completion?(.failure(error))
                    }
                }
            }
        } catch {
            completion?(.failure(error))
        }
    }

    public func set(forKey key: String, data: APICachePackage, writeMode: APICacheWriteMode, expiry: APICacheExpiry) throws {
        let resultExpiry: Expiry
        switch expiry {
        case .never:
            resultExpiry = .never
        case let .seconds(seconds):
            resultExpiry = .seconds(seconds)
        case let .date(date):
            resultExpiry = .date(date)
        }

        switch writeMode {
        case .none:
            return
        case .memory:
            getMemoryStorage().setObject(data, forKey: key, expiry: resultExpiry)
        case .disk:
            try getDiskStorage().setObject(data, forKey: key, expiry: resultExpiry)
        case .memoryAndDisk:
            try getStorage().setObject(data, forKey: key, expiry: resultExpiry)
        }
    }

    public func getValidObject(byKey key: String, completion: @escaping (Swift.Result<APICachePackage, Error>) -> Void) {
        do {
            let storage = try getStorage()
            storage.async.entry(forKey: key) { result in
                switch result {
                case let .value(value):
                    if value.expiry.isExpired {
                        completion(.failure(APICacheError.expire(key: key, data: value.object)))
                    }
                    completion(.success(value.object))
                case let .error(error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    public func getValidObject(byKey key: String) throws -> APICachePackage {
        let entry = try getStorage().entry(forKey: key)
        if entry.expiry.isExpired {
            throw APICacheError.expire(key: key, data: entry.object)
        }

        return entry.object
    }
}
