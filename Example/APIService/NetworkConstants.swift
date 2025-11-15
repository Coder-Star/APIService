//
//  NetworkConstants.swift
//  LTXiOSUtilsDemo
//
//  Created by CoderStar on 2022/3/18.
//

import Foundation

enum Env {
    case dev
    case prod
}

struct NetworkConstants {
    static let baseProdURL = URL(string: "https://m1.apifoxmock.com/m1/7410343-7143360-default")!

    // 不可用，显示使用
    static let baseDevURL = URL(string: "https://m1.apifoxmock.com/m1/7410343-7143360-default")!
    static let baseMockURL = URL(string: "https://m1.apifoxmock.com/m1/7410343-7143360-default")!

    static let env: Env = .prod
}
