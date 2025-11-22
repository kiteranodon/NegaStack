//
//  DebugLogger.swift
//  NegaStack
//
//  Created by 千田海生 on 2025/11/21.
//

import Foundation

/// デバッグログ用ヘルパー（リリースビルドでは自動的に無効化）
struct DebugLogger {
    static func log(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        let message = items.map { "\($0)" }.joined(separator: " ")
        print("[\(filename):\(line)] \(message)")
        #endif
    }
}

// 短縮版
func dlog(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    let message = items.map { "\($0)" }.joined(separator: " ")
    print(message)
    #endif
}

