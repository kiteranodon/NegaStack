//
//  StackLog.swift
//  NegaStack
//
//  Created by 千田海生 on 2025/11/21.
//

import SwiftUI

struct StackLog: View {
    @Environment(\.dismiss) var dismiss
    @State private var entries: [JournalEntry] = []
    @State private var fullChargeEntries: [FullChargeEntry] = []
    @State private var isLoading = true
    @State private var sortAscending = false // デフォルトは降順（新しい順）
    
    private let primaryColor = Color(hex: "007C8A")
    
    // エントリと全快完了を統合した表示用データ型
    enum LogItem: Identifiable {
        case journalEntry(JournalEntry)
        case fullCharge(FullChargeEntry)
        
        var id: String {
            switch self {
            case .journalEntry(let entry):
                return "journal_\(entry.id)"
            case .fullCharge(let entry):
                return "fullCharge_\(entry.id)"
            }
        }
        
        var date: Date {
            switch self {
            case .journalEntry(let entry):
                return entry.date
            case .fullCharge(let entry):
                return entry.date
            }
        }
    }
    
    // ソート済みのログアイテム
    private var sortedLogItems: [LogItem] {
        var items: [LogItem] = []
        items.append(contentsOf: entries.map { .journalEntry($0) })
        items.append(contentsOf: fullChargeEntries.map { .fullCharge($0) })
        
        return items.sorted { item1, item2 in
            if sortAscending {
                return item1.date < item2.date
            } else {
                return item1.date > item2.date
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FFF8F0")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // ソート切り替えボタン
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                sortAscending.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                                Text(sortAscending ? "昇順" : "降順")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(primaryColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 8)
                    }
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: primaryColor))
                            .scaleEffect(1.5)
                        Spacer()
                    } else if sortedLogItems.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "square.stack.3d.up")
                                .font(.system(size: 60))
                                .foregroundColor(primaryColor.opacity(0.3))
                            Text("まだ記録がありません")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color(hex: "666666"))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(sortedLogItems) { item in
                                    switch item {
                                    case .journalEntry(let entry):
                                        JournalEntryCard(entry: entry, primaryColor: primaryColor)
                                    case .fullCharge(let entry):
                                        FullChargeCard(entry: entry, primaryColor: primaryColor)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
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
                    Text("記録一覧")
                        .font(.headline)
                        .foregroundColor(primaryColor)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadAllData()
        }
    }
    
    // データを読み込む
    private func loadAllData() {
        isLoading = true
        
        // ジャーナルエントリを取得
        FirebaseManager.shared.getAllEntries(limit: 100) { result in
            switch result {
            case .success(let fetchedEntries):
                self.entries = fetchedEntries
                print("✅ \(fetchedEntries.count)件のジャーナルエントリを取得")
            case .failure(let error):
                print("❌ エントリ取得エラー: \(error.localizedDescription)")
            }
            
            // 全快完了も取得（全快完了用のメソッドを追加する必要があります）
            loadFullCharges()
        }
    }
    
    // 全快完了データを読み込む
    private func loadFullCharges() {
        FirebaseManager.shared.getAllFullCharges(limit: 100) { result in
            switch result {
            case .success(let fetchedEntries):
                self.fullChargeEntries = fetchedEntries
                print("✅ \(fetchedEntries.count)件の全快完了を取得")
            case .failure(let error):
                print("❌ 全快完了取得エラー: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}

// ジャーナルエントリのカード表示
struct JournalEntryCard: View {
    let entry: JournalEntry
    let primaryColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー: 日時とアイコン
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(primaryColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatDate(entry.date))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(primaryColor)
                    Text(formatTime(entry.date))
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "666666"))
                }
                
                Spacer()
                
                // アクションタイプ
                Text(entry.actionType == "rest" ? "休息" : "即スタート")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(entry.actionType == "rest" ? Color(hex: "69b076") : primaryColor)
                    .cornerRadius(12)
            }
            
            // ネガティブな気持ち
            if !entry.negativeFeeling.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("気持ち")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "999999"))
                    Text(entry.negativeFeeling)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                }
            }
            
            // 感情タグ
            if !entry.emotions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("感情")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "999999"))
                    FlowLayout(spacing: 6) {
                        ForEach(entry.emotions, id: \.name) { emotion in
                            Text(emotion.name)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: emotion.colorHex))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            // 考え
            if !entry.thinkings.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("考え")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "999999"))
                    ForEach(entry.thinkings, id: \.self) { thinking in
                        Text("• \(thinking)")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // 休息活動
            if !entry.restActivity.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "69b076"))
                    Text(entry.restActivity)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// 全快完了のカード表示
struct FullChargeCard: View {
    let entry: FullChargeEntry
    let primaryColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "69b076"))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("全快完了")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "69b076"))
                Text(formatDateTime(entry.date))
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "666666"))
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(hex: "F0FFF4"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "69b076").opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日(E) HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// FlowLayoutヘルパー（感情タグを自然に折り返すため）
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, subviewSize.height)
                currentX += subviewSize.width + spacing
                size.width = max(size.width, currentX)
            }
            
            size.height = currentY + lineHeight
            self.size = size
            self.positions = positions
        }
    }
}

#Preview {
    StackLog()
}

