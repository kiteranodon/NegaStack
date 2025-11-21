//
//  ContentView.swift
//  NegaStack
//
//  Created by 千田海生 on 2025/11/20.
//

import SwiftUI

struct ContentView: View {
    @State private var showActualApp = false
    
    var body: some View {
        Group {
            if showActualApp {
                // 実際のアプリ
                StartScreen()
                    .onAppear {
                        print("✅ StartScreenが表示されました")
                    }
            } else {
                // デバッグ用シンプル画面
                ZStack {
                    Color.blue.ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        Text("NegaStack")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("デバッグモード")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        
                        Text("この画面が見えていますか？")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                        
                        Button(action: {
                            print("🔵 ボタンがタップされました")
                            showActualApp = true
                        }) {
                            Text("実際のアプリを起動")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .onAppear {
                    print("🔵🔵🔵 デバッグ画面が表示されました 🔵🔵🔵")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
