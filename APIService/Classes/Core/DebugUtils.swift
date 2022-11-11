//
//  DebugUtils.swift
//  CSAPIService
//
//  Created by CoderStar on 2022/9/22.
//

import Foundation

public typealias LoggingFunctionType = (String) -> Void

struct DebugUtils {
    public static var loggingFunction: LoggingFunctionType? {
        get { return _loggingFunction }
        set { _loggingFunction = newValue }
    }

    private static var _loggingFunction: LoggingFunctionType? = { print($0) }

    static func log<T>(_ log: T, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        if APIConfig.shared.debugLogEnabled {
            printLog(log, file: file, function: function, line: line)
        }
    }

    private static func printLog<T>(_ log: T, file: String, function: String, line: Int) {
        let fileExtension = ((file as NSString).lastPathComponent as NSString).pathExtension // 文件名称
        let filename = ((file as NSString).lastPathComponent as NSString).deletingPathExtension // 文件扩展名
        let time = getCurrentTime()
        let informationPart = "\(time)-\(filename).\(fileExtension):\(line) \(function):"

        let message = "\(informationPart)\(log)"

        _loggingFunction?(message)
    }

    private static func getCurrentTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar.current
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: Date())
        return dateString
    }
}
