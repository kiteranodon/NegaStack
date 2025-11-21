//
//  StartScreen.swift
//  NegaStack
//
//  Created by 千田海生 on 2025/11/21.
//

import SwiftUI

struct StartScreen: View {
    // ユーザーネーム（後で変更可能）
    @State private var username: String = "ユーザー"
    
    // ナビゲーション用の状態
    @State private var showHomeScreen = false
    @State private var showLogJournal = false
    
    // 基本色
    private let primaryColor = Color(hex: "007C8A")
    
    var body: some View {
        ZStack {
            // 地層の背景
            StratumBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // アプリ名とユーザーネームをテキストボックスに
                VStack(spacing: 10) {
                    // アプリ名
                    Text("NegaStack")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(primaryColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // ユーザーネーム
                    Text("\(username)さん")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(primaryColor.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.vertical, 25)
                .padding(.horizontal, 20)
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(primaryColor, lineWidth: 3)
                )
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
                
                // 今日の記録クイックスタートボタン
                Button(action: {
                    showLogJournal = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "pencil")
                            .font(.system(size: 28))
                        Text("今日の記録クイックスタート")
                            .font(.system(size: 24, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20 * 1.7)
                    .padding(.horizontal)
                    .background(primaryColor)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                
                // 休憩完了とホームボタン
                HStack(spacing: 20) {
                    // 休憩完了ボタン
                    Button(action: {
                        // アクション（後で実装）
                        print("休憩完了")
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.arms.open")
                                .font(.system(size: 24))
                            Text("休憩完了")
                                .font(.system(size: 20, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16 * 1.7)
                        .padding(.horizontal)
                        .background(Color(hex: "69b076"))
                        .cornerRadius(12)
                    }
                    
                    // ホームボタン
                    Button(action: {
                        showHomeScreen = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 24))
                            Text("ホーム")
                                .font(.system(size: 20, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16 * 1.7)
                        .padding(.horizontal)
                        .background(Color(hex: "FAA755"))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showHomeScreen) {
            HomeScreen()
        }
        .fullScreenCover(isPresented: $showLogJournal) {
            LogJournal()
        }
    }
}

// 地層風の背景
struct StratumBackground: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 地層のような層を重ねる
                StratumLayer(color: Color(hex: "E8D5B7"), height: 0.15, totalHeight: geometry.size.height)
                StratumLayer(color: Color(hex: "C9B18F"), height: 0.12, totalHeight: geometry.size.height)
                StratumLayer(color: Color(hex: "A68B6A"), height: 0.10, totalHeight: geometry.size.height)
                StratumLayer(color: Color(hex: "8B7355"), height: 0.13, totalHeight: geometry.size.height)
                StratumLayer(color: Color(hex: "6D5B4A"), height: 0.15, totalHeight: geometry.size.height)
                StratumLayer(color: Color(hex: "5A4A3D"), height: 0.12, totalHeight: geometry.size.height)
                StratumLayer(color: Color(hex: "4A3A2F"), height: 0.23, totalHeight: geometry.size.height)
            }
        }
    }
}

// 地層の1つの層
struct StratumLayer: View {
    let color: Color
    let height: CGFloat
    let totalHeight: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 基本色
                color
                
                // 不規則な境界線を表現するための波線（ランダムな要素を削除してビルドを安定化）
                Path { path in
                    let width = geometry.size.width
                    let layerHeight = geometry.size.height
                    
                    path.move(to: CGPoint(x: 0, y: layerHeight * 0.8))
                    
                    var offset: CGFloat = 0
                    for i in stride(from: 0, through: width, by: 30) {
                        offset = (offset == 0) ? 3 : -3
                        path.addLine(to: CGPoint(x: i, y: layerHeight * 0.8 + offset))
                    }
                    
                    path.addLine(to: CGPoint(x: width, y: layerHeight))
                    path.addLine(to: CGPoint(x: 0, y: layerHeight))
                    path.closeSubpath()
                }
                .fill(color.opacity(0.3))
            }
        }
        .frame(height: totalHeight * height)
    }
}

#Preview {
    StartScreen()
}

