//
//  ViewController.swift
//  APIService
//
//  Created by CoderStar on 04/09/2022.
//  Copyright (c) 2022 CoderStar. All rights reserved.
//

import APIService
import BetterCodable
import Foundation
import SVProgressHUD
import UIKit

class ViewController: UIViewController {
    private enum ListAction: Int, CaseIterable {
        case request
        case cacheRequest
        case asyncRequestNoCache
        case asyncRequestWithCache
        case asyncSequenceMultipleCallback
        case download

        var title: String {
            switch self {
            case .request:
                return "请求"
            case .cacheRequest:
                return "带缓存请求"
            case .asyncRequestNoCache:
                return "Async无缓存"
            case .asyncRequestWithCache:
                return "Async带缓存"
            case .asyncSequenceMultipleCallback:
                return "AsyncSequence多次回调"
            case .download:
                return "下载文件"
            }
        }
    }

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tableFooterView = UIView()
        return tableView
    }()

    lazy var networkActivityPlugin: NetworkActivityPlugin = {
        let networkActivityPlugin = NetworkActivityPlugin { change in
            switch change {
            case .began:
                SVProgressHUD.show()
            case .ended:
                SVProgressHUD.dismiss()
            }
        }
        return networkActivityPlugin
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "首页"
        view.backgroundColor = .white

        setupTableView()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.backgroundColor = .white
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        ListAction.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .white
        cell.contentView.backgroundColor = .white
        cell.selectionStyle = .none
        if let action = ListAction(rawValue: indexPath.row) {
            if #available(iOS 14.0, *) {
                var content = cell.defaultContentConfiguration()
                content.text = action.title
                content.textProperties.color = .black
                cell.contentConfiguration = content
            } else {
                cell.textLabel?.text = action.title
                cell.textLabel?.textColor = .black
            }
        }
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let action = ListAction(rawValue: indexPath.row) else {
            return
        }
        switch action {
        case .request:
            getHomeBannerData()
        case .cacheRequest:
            getCacheHomeBannerData()
        case .asyncRequestNoCache:
            getAsyncHomeBannerData()
        case .asyncRequestWithCache:
            getAsyncCachedHomeBannerData()
        case .asyncSequenceMultipleCallback:
            getAsyncSequenceMultipleCallback()
        case .download:
            downloadFile()
        }
    }
}

// MARK: - 基础方式

extension ViewController {
    @objc
    private func getHomeBannerData() {
        let launchAdRequest = ExampleAPI.LaunchAdRequest()

        APIService.sendRequest(launchAdRequest, plugins: [networkActivityPlugin]) { response, type in
            switch type {
            case .network:
                switch response.result.validateResult {
                case let .success(info, _):
                    SVProgressHUD.showInfo(withStatus: "网络结果")
                    debugPrint(info)
                case let .failure(_, error):
                    debugPrint(error)
                }
            case .cache:
                debugPrint(response)
                if response.result.isSuccess {
                    SVProgressHUD.showInfo(withStatus: "缓存")
                }
            }
        }
    }

    @objc
    private func getCacheHomeBannerData() {
        let homeBannerRequest = ExampleAPI.HomeBannerRequest()
        APIService.sendRequest(homeBannerRequest, plugins: [networkActivityPlugin], cacheHandler: { response in
            debugPrint(response)
            if response.result.isSuccess {
                SVProgressHUD.showInfo(withStatus: "缓存")
            }
        }, completionHandler: { response in
            switch response.result.validateResult {
            case let .success(info, _):
                SVProgressHUD.showInfo(withStatus: "网络结果")
                debugPrint(info)
            case let .failure(_, error):
                debugPrint(error)
            }
        })
    }
}

// MARK: - async方式

extension ViewController {
    private func getAsyncHomeBannerData() {
        Task {
            let launchAdRequest = ExampleAPI.LaunchAdRequest()
            do {
                let response = try await APIService.sendRequestAsync(launchAdRequest, plugins: [networkActivityPlugin])
                let (data, msg) = try response.validated()
                debugPrint(data, msg)
                await MainActor.run {
                    SVProgressHUD.showInfo(withStatus: "异步网络结果（无缓存）")
                    debugPrint(data)
                }
            } catch {
                await MainActor.run {
                    SVProgressHUD.showError(withStatus: "异步异常（无缓存）")
                    debugPrint(error)
                }
            }
        }
    }

    private func getAsyncCachedHomeBannerData() {
        Task {
            let homeBannerRequest = ExampleAPI.HomeBannerRequest()
            do {
                let response = try await APIService.sendRequestAsync(homeBannerRequest, plugins: [networkActivityPlugin])
                let (data, msg) = try response.validated()
                debugPrint(data, msg)

                await MainActor.run {
                    SVProgressHUD.showInfo(withStatus: "异步结果（带缓存）")
                    debugPrint(data)
                }
            } catch {
                await MainActor.run {
                    SVProgressHUD.showError(withStatus: "异步异常")
                    debugPrint(error)
                }
            }
        }
    }

    private func getAsyncSequenceMultipleCallback() {
        Task {
            // 使用 alsoNetworkWithCallback 模式才会真正多次回调
            let multipleCallbackRequest = ExampleAPI.MultipleCallbackRequest()
            var callbackCount = 0

            for await (response, sourceType) in APIService.sendRequestSequence(multipleCallbackRequest, plugins: [networkActivityPlugin]) {
                callbackCount += 1
                debugPrint("第\(callbackCount)次回调，来源：\(sourceType)")

                switch sourceType {
                case .cache:
                    // 处理缓存数据
                    if response.result.isSuccess {
                        await MainActor.run {
                            SVProgressHUD.showInfo(withStatus: "第\(callbackCount)次：缓存数据")
                            debugPrint("缓存数据", response)
                        }
                    } else {
                        debugPrint("缓存失败", response.result.error ?? "")
                    }

                case .network:
                    // 处理网络数据
                    do {
                        let (data, msg) = try response.validated()
                        await MainActor.run {
                            SVProgressHUD.showSuccess(withStatus: "第\(callbackCount)次：网络数据")
                            debugPrint("网络数据", data, msg)
                        }
                    } catch {
                        await MainActor.run {
                            SVProgressHUD.showError(withStatus: "网络异常")
                            debugPrint("网络错误", error)
                        }
                    }
                }
            }

            debugPrint("AsyncSequence 完成，总共回调 \(callbackCount) 次")
        }
    }
}

// MARK: - 下载

extension ViewController {
    @objc
    private func downloadFile() {
        let downloadURL = URL(string: "https://picsum.photos/200/200.jpg")!
        var savedFilePath: String?

        let downloadRequest = ExampleAPI.DownloadRequest(downloadURL: downloadURL) { filePath in
            savedFilePath = filePath
        }

        APIService.sendRequest(downloadRequest, plugins: [networkActivityPlugin]) { response in
            if response.statusCode == 200 {
                SVProgressHUD.showInfo(withStatus: "下载成功")
                if let filePath = savedFilePath {
                    debugPrint("文件已保存到:", filePath)
                }
            }
        }
    }
}
