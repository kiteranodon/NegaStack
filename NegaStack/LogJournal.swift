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
    @FocusState private var isTextEditorFocused: Bool
    
    private let primaryColor = Color(hex: "007C8A")
    
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
                    
                    Spacer()
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

#Preview {
    LogJournal()
}

