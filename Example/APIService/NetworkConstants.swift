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
    static let baseProdURL = URL(string: "https://www.fastmock.site/mock/5abd18409d0a2270b34088a07457e68f/LTXMock")!

    // 不可用，显示使用
    static let baseDevURL = URL(string: "https://www.fastmock.site/mock/5abd18409d0a2270b34088a07457e68f/LTXMock1")!
    static let baseMockURL = URL(string: "https://www.fastmock.site/mock/5abd18409d0a2270b34088a07457e68f/LTXMock2")!

    static let env: Env = .prod
}
