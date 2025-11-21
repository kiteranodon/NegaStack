//
//  FullCharge.swift
//  NegaStack
//
//  Created by 千田海生 on 2025/11/21.
//

import SwiftUI

// 全快処理の共通ロジック
struct FullChargeHandler {
    private static let firebaseManager = FirebaseManager.shared
    
    // 全快完了をFirebaseに保存
    static func saveFullCharge(source: String) {
        let entry = FullChargeEntry(date: Date(), source: source)
        
        firebaseManager.saveFullChargeEntry(entry) { result in
            switch result {
            case .success:
                print("✅ 全快完了をFirebaseに保存しました")
                print("   日時: \(entry.date)")
                print("   ソース: \(source)")
            case .failure(let error):
                print("❌ 全快完了の保存エラー: \(error.localizedDescription)")
            }
        }
    }
    
    // 全快完了時のメッセージを表示するアラートを生成
    static func createCompletionAlert(isPresented: Binding<Bool>, source: String) -> Alert {
        Alert(
            title: Text("全快完了"),
            message: Text("よく休めましたか？辛いときはまた記録してみましょう！"),
            dismissButton: .default(Text("OK")) {
                // OKボタンが押されたらFirebaseに保存
                saveFullCharge(source: source)
            }
        )
    }
}

// 全快ボタン用のViewModifier
struct FullChargeAlertModifier: ViewModifier {
    @Binding var showAlert: Bool
    let source: String
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: $showAlert) {
                FullChargeHandler.createCompletionAlert(isPresented: $showAlert, source: source)
            }
    }
}

// ViewにFullChargeアラートを追加するための拡張
extension View {
    func fullChargeAlert(isPresented: Binding<Bool>, source: String) -> some View {
        modifier(FullChargeAlertModifier(showAlert: isPresented, source: source))
    }
}

