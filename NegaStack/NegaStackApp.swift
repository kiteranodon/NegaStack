//
//  NegaStackApp.swift
//  NegaStack
//
//  Created by 千田海生 on 2025/11/20.
//

import SwiftUI
import UserNotifications

// 通知デリゲート
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // アプリがフォアグラウンドにいる時に通知を表示
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📱 通知が届きました（フォアグラウンド）")
        completionHandler([.banner, .sound, .badge])
    }
    
    // 通知をタップした時の処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("📱 通知がタップされました")
        completionHandler()
    }
}

@main
struct NegaStackApp: App {
    init() {
        // 通知デリゲートを設定
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // 通知権限をリクエスト
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ 通知権限エラー: \(error.localizedDescription)")
            } else {
                print(granted ? "✅ 通知権限が許可されました" : "❌ 通知権限が拒否されました")
            }
        }
        
        print("🚀 アプリ起動完了")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
