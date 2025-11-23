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
    @State private var showInsights = false // 洞察画面の表示フラグ
    
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
                
                // AI洞察ボタン
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showInsights = true
                    }) {
                        Text("AI")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(primaryColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(primaryColor.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showInsights) {
            InsightsView(entries: entries, fullChargeEntries: fullChargeEntries, primaryColor: primaryColor)
        }
        .onAppear {
            print("🔍 StackLog画面が表示されました")
            loadAllData()
        }
    }
    
    // データを読み込む
    private func loadAllData() {
        print("🔄 データ読み込み開始...")
        
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        // ジャーナルエントリを取得（最初は30件に制限してメモリを節約）
        FirebaseManager.shared.getAllEntries(limit: 30) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedEntries):
                    print("✅ \(fetchedEntries.count)件のジャーナルエントリを取得")
                    print("   fetchedEntriesの中身を確認:")
                    for (index, entry) in fetchedEntries.enumerated() {
                        print("   [\(index)] ID: \(entry.id), 気持ち: \(entry.negativeFeeling), 日付: \(entry.date)")
                    }
                    
                    self.entries = fetchedEntries
                    print("   self.entriesに代入完了。現在のentries数: \(self.entries.count)")
                    
                    if fetchedEntries.isEmpty {
                        print("⚠️ ジャーナルエントリが0件です。")
                    }
                case .failure(let error):
                    print("❌ エントリ取得エラー: \(error.localizedDescription)")
                    self.entries = []
                }
                
                // 全快完了も取得
                self.loadFullCharges()
            }
        }
    }
    
    // 全快完了データを読み込む
    private func loadFullCharges() {
        FirebaseManager.shared.getAllFullCharges(limit: 30) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedEntries):
                    print("✅ \(fetchedEntries.count)件の全快完了を取得")
                    self.fullChargeEntries = fetchedEntries
                    print("   self.fullChargeEntriesに代入完了。現在のfullChargeEntries数: \(self.fullChargeEntries.count)")
                    
                    if fetchedEntries.isEmpty {
                        print("⚠️ 全快完了が0件です。")
                    }
                case .failure(let error):
                    print("❌ 全快完了取得エラー: \(error.localizedDescription)")
                    self.fullChargeEntries = []
                }
                
                self.isLoading = false
                
                let totalItems = self.entries.count + self.fullChargeEntries.count
                print("📊 最終確認 - 合計: \(totalItems)件のデータ")
                print("   - ジャーナルエントリ: \(self.entries.count)件")
                print("   - 全快完了: \(self.fullChargeEntries.count)件")
                print("   - sortedLogItems.count: \(self.sortedLogItems.count)件")
                print("   - isLoading: \(self.isLoading)")
                
                if totalItems == 0 {
                    print("💡 データがありません。")
                } else {
                    print("🎉 データが存在します！sortedLogItemsを確認:")
                    for (index, item) in self.sortedLogItems.enumerated() {
                        switch item {
                        case .journalEntry(let entry):
                            print("   [\(index)] ジャーナル: \(entry.negativeFeeling)")
                        case .fullCharge(let entry):
                            print("   [\(index)] 全快: \(entry.date)")
                        }
                    }
                }
            }
        }
    }
}

// DateFormatterキャッシュ（メモリ最適化）
private class DateFormatters {
    static let shared = DateFormatters()
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
    
    lazy var dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日(E) HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
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
            
            // 次のタスク
            if !entry.nextTask.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("次のタスク")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: "999999"))
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 12))
                            .foregroundColor(primaryColor)
                        Text(entry.nextTask)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // タスク所要時間
            if entry.taskDurationMinutes > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "FAA755"))
                    let hours = entry.taskDurationMinutes / 60
                    let minutes = entry.taskDurationMinutes % 60
                    if hours > 0 && minutes > 0 {
                        Text("所要時間: \(hours)時間\(minutes)分")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                    } else if hours > 0 {
                        Text("所要時間: \(hours)時間")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                    } else {
                        Text("所要時間: \(minutes)分")
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
        return DateFormatters.shared.dateFormatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        return DateFormatters.shared.timeFormatter.string(from: date)
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
        return DateFormatters.shared.dateTimeFormatter.string(from: date)
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

// 洞察レポートビュー
struct InsightsView: View {
    @Environment(\.dismiss) var dismiss
    let entries: [JournalEntry]
    let fullChargeEntries: [FullChargeEntry]
    let primaryColor: Color
    
    @State private var insightReport: String = ""
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FFF8F0")
                    .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: primaryColor))
                            .scaleEffect(1.5)
                        Text("洞察を生成中...")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text(insightReport)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .lineSpacing(8)
                                .padding()
                        }
                        .padding(.bottom, 100)
                    }
                    
                    VStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Text("OK")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(primaryColor)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "FFF8F0").opacity(0), Color(hex: "FFF8F0")]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 120)
                            .offset(y: -100)
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("洞察")
                        .font(.headline)
                        .foregroundColor(primaryColor)
                }
            }
        }
        .onAppear {
            generateInsights()
        }
    }
    
    private func generateInsights() {
        print("🤖 洞察レポート生成開始...")
        
        // 非同期で歩数データを取得してから分析
        DispatchQueue.global(qos: .userInitiated).async {
            // 歩数データの取得期間を決定
            var earliestDate = Date()
            var latestDate = Date()
            
            if let first = entries.first?.date, let last = entries.last?.date {
                earliestDate = min(first, last)
                latestDate = max(first, last)
            }
            
            // 歩数データを取得
            StepCountManager.shared.fetchStepCounts(from: earliestDate, to: latestDate) { stepsByDate, error in
                DispatchQueue.main.async {
                    let report = self.analyzeData(stepsByDate: stepsByDate ?? [:])
                    self.insightReport = report
                    self.isLoading = false
                }
            }
        }
    }
    
    private func analyzeData(stepsByDate: [Date: Double]) -> String {
        var report = ""
        
        // データがない場合
        if entries.isEmpty {
            return """
            データがまだ十分にありません。
            
            記録を続けることで、あなたの心の状態やスマホ休憩のパターンを分析し、より良いアドバイスをお届けできるようになります。
            
            まずは気持ちが辛いときに記録してみましょう。
            """
        }
        
        // 1. 記入頻度の平均
        let frequency = calculateFrequency()
        report += "【記録の習慣】\n"
        report += frequency + "\n\n"
        
        // 2. 内容の要約
        let summary = summarizeContent()
        report += "【あなたの心の傾向】\n"
        report += summary + "\n\n"
        
        // 3. 5000歩以上歩いた日の寝不足分析
        let stepAnalysis = analyzeStepsAndSleep(stepsByDate: stepsByDate)
        report += "【活動と睡眠の関係】\n"
        report += stepAnalysis + "\n\n"
        
        // 4. 寝不足時の感情分析
        let sleepEmotionAnalysis = analyzeSleepDeprivedEmotions()
        report += "【寝不足と感情の関係】\n"
        report += sleepEmotionAnalysis + "\n\n"
        
        // 5. スマホ休憩のアドバイス
        let advice = generateAdvice()
        report += "【スマホ休憩のアドバイス】\n"
        report += advice
        
        return report
    }
    
    // 記入頻度の計算
    private func calculateFrequency() -> String {
        guard entries.count > 1 else {
            return "記録はまだ\(entries.count)件です。続けて記録することで、あなたのパターンが見えてきます。"
        }
        
        let sortedEntries = entries.sorted { $0.date < $1.date }
        
        var intervals: [Double] = []
        for i in 1..<sortedEntries.count {
            let interval = sortedEntries[i].date.timeIntervalSince(sortedEntries[i-1].date)
            intervals.append(interval / 86400) // 日数に変換
        }
        
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        
        let totalDays = sortedEntries.last!.date.timeIntervalSince(sortedEntries.first!.date) / 86400
        
        if averageInterval < 1 {
            return "あなたは平均して毎日記録しています（合計\(entries.count)件、\(Int(totalDays))日間）。心と向き合う習慣が素晴らしいですね。"
        } else if averageInterval < 3 {
            return "あなたは\(String(format: "%.1f", averageInterval))日に1回のペースで記録しています（合計\(entries.count)件）。コンスタントに自分の気持ちと向き合えています。"
        } else if averageInterval < 7 {
            return "あなたは約\(Int(averageInterval))日に1回のペースで記録しています（合計\(entries.count)件）。辛いときに記録する習慣ができつつありますね。"
        } else {
            return "あなたは週に1回程度記録しています（合計\(entries.count)件）。無理のないペースで続けていきましょう。"
        }
    }
    
    // 内容の要約
    private func summarizeContent() -> String {
        var summary = ""
        
        // 感情の集計
        var emotionCounts: [String: Int] = [:]
        for entry in entries {
            for emotion in entry.emotions {
                emotionCounts[emotion.name, default: 0] += 1
            }
        }
        
        let topEmotions = emotionCounts.sorted { $0.value > $1.value }.prefix(3)
        if !topEmotions.isEmpty {
            let emotionList = topEmotions.map { "\($0.key)(\($0.value)回)" }.joined(separator: "、")
            summary += "よく感じている気持ちは「\(emotionList)」です。"
            summary += "\n"
        }
        
        // 「何について」の集計
        var thinkingCounts: [String: Int] = [:]
        for entry in entries {
            for thinking in entry.thinkings {
                thinkingCounts[thinking, default: 0] += 1
            }
        }
        
        let topThinkings = thinkingCounts.sorted { $0.value > $1.value }.prefix(3)
        if !topThinkings.isEmpty {
            let thinkingList = topThinkings.map { "\($0.key)(\($0.value)回)" }.joined(separator: "、")
            summary += "気になっていることは主に「\(thinkingList)」です。"
            summary += "\n"
        }
        
        // アクションタイプの分析
        let restCount = entries.filter { $0.actionType == "rest" }.count
        let quickStartCount = entries.filter { $0.actionType == "quickStart" }.count
        
        if restCount > quickStartCount {
            let percentage = Int(Double(restCount) / Double(entries.count) * 100)
            summary += "\n\(percentage)%の記録で休憩を選んでいます。自分をいたわる姿勢が素晴らしいです。"
        } else if quickStartCount > restCount {
            let percentage = Int(Double(quickStartCount) / Double(entries.count) * 100)
            summary += "\n\(percentage)%の記録ですぐ動き出すを選んでいます。前向きに行動できていますね。"
        }
        
        return summary.isEmpty ? "データから傾向を分析中です。もう少し記録を続けてみましょう。" : summary
    }
    
    // 5000歩以上と寝不足の関係
    private func analyzeStepsAndSleep(stepsByDate: [Date: Double]) -> String {
        guard !stepsByDate.isEmpty else {
            return "歩数データが取得できませんでした。HealthKitへのアクセスを許可すると、活動量と睡眠の関係を分析できます。"
        }
        
        var over5000StepsCount = 0
        var over5000AndSleepDeprived = 0
        var over5000AndWellRested = 0
        
        for (stepDate, steps) in stepsByDate {
            if steps >= 5000 {
                over5000StepsCount += 1
                
                // その日のエントリを探す
                let dateKey = formatDateKey(stepDate)
                let entriesOnDate = entries.filter { $0.dateKey == dateKey }
                
                if let latestEntry = entriesOnDate.sorted(by: { $0.date > $1.date }).first {
                    if latestEntry.isSleepDeprived == true {
                        over5000AndSleepDeprived += 1
                    } else {
                        over5000AndWellRested += 1
                    }
                } else {
                    // データがない = 睡眠は十分とする
                    over5000AndWellRested += 1
                }
            }
        }
        
        if over5000StepsCount == 0 {
            return "5000歩以上歩いた日がまだありません。適度な運動は心身の健康に良い影響を与えます。"
        }
        
        let totalAnalyzed = over5000AndSleepDeprived + over5000AndWellRested
        let wellRestedPercentage = totalAnalyzed > 0 ? Int(Double(over5000AndWellRested) / Double(totalAnalyzed) * 100) : 0
        
        var analysis = "5000歩以上歩いた日は\(over5000StepsCount)日あります。"
        
        if totalAnalyzed > 0 {
            analysis += "そのうち\(wellRestedPercentage)%は十分な睡眠が取れていました。"
            
            if wellRestedPercentage >= 70 {
                analysis += "\nよく歩く日は睡眠も十分な傾向があります。良い生活リズムができていますね。"
            } else if wellRestedPercentage >= 40 {
                analysis += "\nよく歩く日でも寝不足になることがあるようです。活動と休息のバランスを意識しましょう。"
            } else {
                analysis += "\nよく歩く日でも寝不足が多いようです。体を動かした日こそ、しっかり休息を取ることが大切です。"
            }
        }
        
        return analysis
    }
    
    // 寝不足時の感情分析
    private func analyzeSleepDeprivedEmotions() -> String {
        let sleepDeprivedEntries = entries.filter { $0.isSleepDeprived == true }
        
        guard !sleepDeprivedEntries.isEmpty else {
            return "寝不足の記録がまだありません。睡眠は心の健康に大きく影響します。"
        }
        
        var emotionCounts: [String: Int] = [:]
        for entry in sleepDeprivedEntries {
            for emotion in entry.emotions {
                emotionCounts[emotion.name, default: 0] += 1
            }
        }
        
        let topEmotions = emotionCounts.sorted { $0.value > $1.value }.prefix(3)
        
        var analysis = "寝不足のときは、"
        if !topEmotions.isEmpty {
            let emotionList = topEmotions.map { $0.key }.joined(separator: "、")
            analysis += "「\(emotionList)」といった気持ちになりやすいようです。"
        }
        
        analysis += "\n睡眠不足は感情のコントロールを難しくします。辛いと感じたら、まず睡眠時間を確保することを優先してみましょう。"
        
        return analysis
    }
    
    // アドバイスを生成
    private func generateAdvice() -> String {
        var advice = ""
        
        // 休憩活動の分析
        let restEntries = entries.filter { $0.actionType == "rest" && !$0.restActivity.isEmpty }
        
        if !restEntries.isEmpty {
            var activityCounts: [String: Int] = [:]
            for entry in restEntries {
                let activity = entry.restActivity.lowercased()
                if activity.contains("youtube") || activity.contains("動画") {
                    activityCounts["動画視聴", default: 0] += 1
                } else if activity.contains("音楽") {
                    activityCounts["音楽", default: 0] += 1
                } else if activity.contains("散歩") || activity.contains("歩く") {
                    activityCounts["散歩", default: 0] += 1
                } else if activity.contains("寝る") || activity.contains("睡眠") {
                    activityCounts["仮眠", default: 0] += 1
                }
            }
            
            if let topActivity = activityCounts.max(by: { $0.value < $1.value }) {
                advice += "あなたは\(topActivity.key)で休憩することが多いですね。"
                advice += "\n"
            }
        }
        
        // 寝不足状況に応じたアドバイス
        let sleepDeprivedCount = entries.filter { $0.isSleepDeprived == true }.count
        let sleepDeprivedRatio = Double(sleepDeprivedCount) / Double(entries.count)
        
        if sleepDeprivedRatio > 0.6 {
            advice += "\n睡眠不足が続いています。スマホ休憩も大切ですが、夜はスマホを早めに切り上げて、しっかり睡眠時間を確保することが最優先です。"
        } else if sleepDeprivedRatio > 0.3 {
            advice += "\n時々寝不足になることがあります。疲れを感じたら、スマホ休憩ではなく10-20分の仮眠を取るのも効果的です。"
        } else {
            advice += "\n睡眠はよく取れているようです。スマホ休憩では、画面を見続けるのではなく、体を動かしたり目を休めたりする活動も取り入れてみましょう。"
        }
        
        // 全快完了の状況
        if fullChargeEntries.count > entries.count * 70 / 100 {
            advice += "\n\n素晴らしいです！多くの記録で全快完了できています。休憩後にしっかり回復できている証拠です。この調子で続けていきましょう。"
        } else if fullChargeEntries.count > entries.count * 30 / 100 {
            advice += "\n\n全快完了できることが増えてきています。休息を取ることで気持ちが楽になる実感が持てているのではないでしょうか。"
        } else {
            advice += "\n\n休憩後は「全快完了」ボタンを押して、気持ちの変化を記録してみましょう。回復の実感を持つことも大切です。"
        }
        
        return advice
    }
    
    // 日付キーをフォーマット
    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }
}

