//
//  LogJournal.swift
//  NegaStack
//
//  Created by 千田海生 on 2025/11/21.
//

import SwiftUI

struct LogJournal: View {
    @Environment(\.dismiss) var dismiss
    @State private var negativeFeeling: String = ""
    @State private var selectedEmotions: Set<String> = []
    @State private var customEmotion: String = ""
    @FocusState private var isTextEditorFocused: Bool
    
    private let primaryColor = Color(hex: "007C8A")
    
    // 感情データ
    private let fineEmotions = ["スッキリ", "ドキドキ", "安心", "穏やか", "普通", "退屈", "モヤモヤ", "緊張"]
    private let negativeEmotions = ["不安", "悲しい", "疲れた", "後悔", "恐れる", "イライラ", "怒り", "嫌い"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 案内テキスト
                    VStack(spacing: 12) {
                        Text("今のネガティブな気持ちを")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(primaryColor)
                        Text("書き出してみましょう")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(primaryColor)
                    }
                    .padding(.top, 30)
                    
                    // テキスト入力エリア
                    VStack(alignment: .leading, spacing: 12) {
                        ZStack(alignment: .topLeading) {
                            // プレースホルダー
                            if negativeFeeling.isEmpty {
                                Text("例: 今日の会議で失敗してしまった...")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                            
                            // テキストエディタ
                            TextEditor(text: $negativeFeeling)
                                .font(.system(size: 16))
                                .focused($isTextEditorFocused)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                        }
                        .frame(height: 200)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(primaryColor.opacity(0.3), lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 30)
                    
                    // 感情選択セクション
                    VStack(spacing: 20) {
                        // タイトル
                        VStack(spacing: 8) {
                            Text("どんな気持ち？")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(primaryColor)
                            Text("必須。3つまで")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        // Fine感情
                        EmotionSection(
                            title: "Fine",
                            emotions: fineEmotions,
                            selectedEmotions: $selectedEmotions,
                            colorStart: Color(hex: "D4C48E"),
                            colorEnd: Color(hex: "A8BA8F")
                        )
                        
                        Divider()
                            .padding(.horizontal, 30)
                        
                        // Negative感情
                        EmotionSection(
                            title: "Negative",
                            emotions: negativeEmotions,
                            selectedEmotions: $selectedEmotions,
                            colorStart: Color(hex: "7FA089"),
                            colorEnd: Color(hex: "7FA8C3")
                        )
                        
                        // 自由入力セクション
                        HStack(spacing: 12) {
                            TextField("4文字まで自由入力", text: $customEmotion)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .onChange(of: customEmotion) { newValue in
                                    if newValue.count > 4 {
                                        customEmotion = String(newValue.prefix(4))
                                    }
                                }
                            
                            Button(action: {
                                if !customEmotion.isEmpty && selectedEmotions.count < 3 {
                                    selectedEmotions.insert(customEmotion)
                                    customEmotion = ""
                                }
                            }) {
                                Text("追加")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 30)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "F5F5F5"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("戻る")
                        }
                        .foregroundColor(primaryColor)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("記録する")
                        .font(.headline)
                        .foregroundColor(primaryColor)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// 感情セクション
struct EmotionSection: View {
    let title: String
    let emotions: [String]
    @Binding var selectedEmotions: Set<String>
    let colorStart: Color
    let colorEnd: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // セクションタイトル
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.leading, 30)
            
            // 感情ボタングリッド
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 20) {
                ForEach(emotions.indices, id: \.self) { index in
                    EmotionButton(
                        emotion: emotions[index],
                        isSelected: selectedEmotions.contains(emotions[index]),
                        color: interpolateColor(
                            start: colorStart,
                            end: colorEnd,
                            fraction: Double(index) / Double(emotions.count - 1)
                        ),
                        action: {
                            toggleEmotion(emotions[index])
                        }
                    )
                }
            }
            .padding(.horizontal, 30)
        }
    }
    
    private func toggleEmotion(_ emotion: String) {
        if selectedEmotions.contains(emotion) {
            selectedEmotions.remove(emotion)
        } else if selectedEmotions.count < 3 {
            selectedEmotions.insert(emotion)
        }
    }
    
    private func interpolateColor(start: Color, end: Color, fraction: Double) -> Color {
        // 簡易的なカラー補間
        let startComponents = UIColor(start).cgColor.components ?? [0, 0, 0, 1]
        let endComponents = UIColor(end).cgColor.components ?? [0, 0, 0, 1]
        
        let r = startComponents[0] + (endComponents[0] - startComponents[0]) * fraction
        let g = startComponents[1] + (endComponents[1] - startComponents[1]) * fraction
        let b = startComponents[2] + (endComponents[2] - startComponents[2]) * fraction
        
        return Color(red: r, green: g, blue: b)
    }
}

// 感情ボタン
struct EmotionButton: View {
    let emotion: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Circle()
                        .fill(color.opacity(0.8))
                        .frame(width: 60, height: 60)
                    
                    Text(emotion)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                // 選択インジケーター
                if isSelected {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 16, height: 16)
                        .offset(x: 8, y: -4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LogJournal()
}

