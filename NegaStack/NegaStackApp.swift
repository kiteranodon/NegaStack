//
//  NegaStackApp.swift
//  NegaStack
//
//  Created by 千田海生 on 2025/11/20.
//

import SwiftUI
import UserNotifications
import FirebaseCore
import FirebaseFirestore

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
        print("========================================")
        print("🚀 NegaStack アプリ起動開始")
        print("========================================")
        
        // 全ての通知をクリア（古い通知を削除）
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("🧹 古い通知をクリアしました")
        
        // 通知デリゲートを設定
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        print("✅ 通知デリゲート設定完了")
        
        // Firebase初期化（バックグラウンドで実行）
        DispatchQueue.global(qos: .userInitiated).async {
            print("⏳ Firebase初期化中（バックグラウンド）...")
            FirebaseApp.configure()
            print("✅ Firebase初期化完了")
            
            // Firestoreの設定
            print("⏳ Firestore設定中...")
            let settings = FirestoreSettings()
            settings.cacheSettings = PersistentCacheSettings() // オフライン対応
            Firestore.firestore().settings = settings
            print("✅ Firestore設定完了")
        }
        
        // 通知権限をリクエスト
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ 通知権限エラー: \(error.localizedDescription)")
            } else {
                print(granted ? "✅ 通知権限が許可されました" : "❌ 通知権限が拒否されました")
            }
        }
        
        print("========================================")
        print("🚀 アプリ起動完了 - UI表示開始")
        print("========================================")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("✅✅✅ ContentViewが表示されました ✅✅✅")
                    // バックグラウンドでUI表示の確認
                    DispatchQueue.main.async {
                        print("✅ メインスレッドでUI更新確認")
                    }
                }
        }
    }
}
