//
//  HomeScreen.swift
//  NegaStack
//
//  Created by 千田海生 on 2025/11/21.
//

import SwiftUI

struct HomeScreen: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showLogJournal = false
    @State private var showStackLog = false
    @State private var hasRecordByDate: Set<String> = [] // 記録（JournalEntry）がある日付
    @State private var hasFullChargeByDate: Set<String> = [] // 全快完了がある日付
    @State private var isSleepDeprivedByDate: [String: Bool] = [:] // 日付ごとの寝不足データ
    
    // 全快完了アラート表示用
    @State private var showFullChargeAlert = false
    
    // 歩数データ
    @State private var stepCount: Double?
    @State private var stepCountAuthorized = false
    @State private var stepCountByDate: [String: Double] = [:] // 日付ごとの歩数データ
    
    private let primaryColor = Color(hex: "007C8A")
    private let calendar = Calendar.current
    private let firebaseManager = FirebaseManager.shared
    private let stepCountManager = StepCountManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 歩数表示セクション（カレンダーの上）
                if stepCountAuthorized, let steps = stepCount {
                    CompactStepCountView(stepCount: steps, primaryColor: primaryColor)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                } else if stepCountAuthorized {
                    // 権限はあるがデータがまだない場合
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("歩数データを読み込み中...")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .frame(height: 40)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                } else if !stepCountAuthorized && stepCountManager.isHealthKitAvailable {
                    // 権限がない場合
                    HStack(spacing: 8) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        Text("歩数データの権限を許可してください")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Button("設定") {
                            if let url = URL(string: "app-settings:") {
                                // iOS設定画面を開く
                                #if canImport(UIKit)
                                UIApplication.shared.open(url)
                                #endif
                            }
                        }
                        .font(.caption2)
                        .foregroundColor(primaryColor)
                    }
                    .frame(height: 40)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                
                // カレンダー
                CalendarView(
                    currentMonth: $currentMonth,
                    selectedDate: $selectedDate,
                    primaryColor: primaryColor,
                    hasRecordByDate: hasRecordByDate,
                    hasFullChargeByDate: hasFullChargeByDate,
                    stepCountByDate: stepCountByDate,
                    isSleepDeprivedByDate: isSleepDeprivedByDate
                )
                .padding(.top, 12)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 下部：4つのボタンと下部メニュー
                VStack(spacing: 16) {
                    // 3つのボタン
                    HStack(spacing: 8) {
                        // Quoteボタン
                        Button(action: {
                            print("Quote")
                        }) {
                            Text("Quote")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "666666"))
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 70, height: 70)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "CCCCCC"), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        // えんぴつボタン（少し大きめ）
                        Button(action: {
                            showLogJournal = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 28))
                                Text("記録する")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(primaryColor)
                        }
                        .frame(width: 91, height: 91)
                        
                        // 全快ボタン
                        Button(action: {
                            showFullChargeAlert = true
                        }) {
                            Text("全快")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 70, height: 70)
                        .background(Color(hex: "69b076"))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
//                    .padding(.horizontal, 20)
                    .frame(height: 110)
                    
                    // 下部メニュー（背景色付き）
                    VStack(spacing: 0) {
                        // 下部メニュー（3つのボタン）
                        HStack(spacing: 0) {
                            // Homeボタン
                            Button(action: {
                                print("Home")
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 22))
                                    Text("Home")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(primaryColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            
                            // Stackボタン
                            Button(action: {
                                print("🔘 Stackボタンがタップされました")
                                showStackLog = true
                                print("📱 showStackLog = \(showStackLog)")
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "square.stack.3d.up.fill")
                                        .font(.system(size: 22))
                                    Text("Stack")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(primaryColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                            
                            // Pillarボタン
                            Button(action: {
                                print("Pillar")
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "building.columns.fill")
                                        .font(.system(size: 22))
                                    Text("Pillar")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(primaryColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                            }
                        }
                    }
                    .background(Color(hex: "FED5B0"))
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
                    Text("ホーム")
                        .font(.headline)
                        .foregroundColor(primaryColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("設定")
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(primaryColor)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $showLogJournal, onDismiss: {
            // LogJournalが閉じられたらデータを再読み込み
            print("🔄 LogJournalが閉じられました。データを再読み込みします")
            loadRecordData()
        }) {
            LogJournal()
        }
        .fullScreenCover(isPresented: $showStackLog) {
            StackLog()
        }
        .alert("全快完了", isPresented: $showFullChargeAlert) {
            Button("OK") {
                // Firebaseに保存
                let entry = FullChargeEntry(date: Date(), source: "homeScreen")
                FirebaseManager.shared.saveFullChargeEntry(entry) { result in
                    switch result {
                    case .success:
                        print("✅ 全快完了を保存しました")
                        // 保存後にデータを再読み込み
                        loadRecordData()
                    case .failure(let error):
                        print("❌ 保存エラー: \(error.localizedDescription)")
                    }
                }
            }
        } message: {
            Text("よく休めましたか？辛いときはまた記録してみましょう！")
        }
        .onAppear {
            print("========================================")
            print("✅ HomeScreen表示完了")
            print("========================================")
            loadRecordData()
            
            // HealthKit利用可能性チェック
            if stepCountManager.isHealthKitAvailable {
                print("✅ HealthKitは利用可能です")
                requestStepCountPermission()
            } else {
                print("❌ HealthKitが利用できません（シミュレーターまたは非対応デバイス）")
            }
        }
        .onChange(of: currentMonth) { oldValue, newValue in
            loadRecordData()
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            loadStepCount(for: newValue)
        }
    }
    
    // 月の記録データを読み込む
    private func loadRecordData() {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return }
        let startDate = monthInterval.start
        let endDate = monthInterval.end
        
        print("📅 HomeScreen: 記録データ取得 \(startDate) ~ \(endDate)")
        
        // ジャーナルエントリを取得
        firebaseManager.getEntriesForDateRange(startDate: startDate, endDate: endDate) { result in
            var journalDates: Set<String> = []
            var sleepDeprivedData: [String: Bool] = [:]
            
            if case .success(let entries) = result {
                print("✅ HomeScreen: \(entries.count)件のジャーナルエントリを取得")
                
                // 日付ごとに最新のエントリを取得
                var latestEntryByDate: [String: JournalEntry] = [:]
                for entry in entries {
                    let dateKey = entry.dateKey
                    journalDates.insert(dateKey)
                    
                    // その日付の最新エントリを保持（日時が最も新しいもの）
                    if let existingEntry = latestEntryByDate[dateKey] {
                        if entry.date > existingEntry.date {
                            latestEntryByDate[dateKey] = entry
                        }
                    } else {
                        latestEntryByDate[dateKey] = entry
                    }
                }
                
                // 最新エントリの寝不足データを抽出
                for (dateKey, entry) in latestEntryByDate {
                    if let isSleepDeprived = entry.isSleepDeprived {
                        sleepDeprivedData[dateKey] = isSleepDeprived
                        if isSleepDeprived {
                            print("   😴 寝不足: \(dateKey)")
                        }
                    }
                }
            }
            
            // 全快完了を取得
            self.firebaseManager.getFullChargesForDateRange(startDate: startDate, endDate: endDate) { fullChargeResult in
                var fullChargeDates: Set<String> = []
                
                if case .success(let fullCharges) = fullChargeResult {
                    print("✅ HomeScreen: \(fullCharges.count)件の全快完了を取得")
                    for fullCharge in fullCharges {
                        fullChargeDates.insert(fullCharge.dateKey)
                        print("   🟢 全快完了: \(fullCharge.dateKey)")
                    }
                }
                
                DispatchQueue.main.async {
                    self.hasRecordByDate = journalDates
                    self.hasFullChargeByDate = fullChargeDates
                    self.isSleepDeprivedByDate = sleepDeprivedData
                    print("📊 🔵 記録: \(journalDates.sorted())")
                    print("📊 🟢 全快: \(fullChargeDates.sorted())")
                    print("📊 😴 寝不足: \(sleepDeprivedData.filter { $0.value }.map { $0.key }.sorted())")
                }
            }
        }
        
        // 歩数データを取得（権限がある場合）
        if stepCountAuthorized {
            loadMonthStepCounts(startDate: startDate, endDate: endDate)
        }
    }
    
    // 月の歩数データを読み込む
    private func loadMonthStepCounts(startDate: Date, endDate: Date) {
        print("🚶 HomeScreen: 月の歩数データ取得中...")
        
        stepCountManager.fetchStepCounts(from: startDate, to: endDate) { stepsByDate, error in
            if let error = error {
                print("❌ 月の歩数データ取得エラー: \(error.localizedDescription)")
                return
            }
            
            if let stepsByDate = stepsByDate {
                // Date -> String に変換
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.locale = Locale(identifier: "ja_JP")
                formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
                
                var stepCountsByDateKey: [String: Double] = [:]
                for (date, steps) in stepsByDate {
                    let dateKey = formatter.string(from: date)
                    stepCountsByDateKey[dateKey] = steps
                    print("   🚶 \(dateKey): \(steps)歩")
                }
                
                DispatchQueue.main.async {
                    self.stepCountByDate = stepCountsByDateKey
                    print("✅ HomeScreen: \(stepCountsByDateKey.count)日分の歩数データを取得")
                }
            }
        }
    }
    
    // 歩数データの権限リクエスト
    private func requestStepCountPermission() {
        print("🚶 歩数データの権限をリクエストしています...")
        stepCountManager.requestAuthorization { success, error in
            DispatchQueue.main.async {
                self.stepCountAuthorized = success
                print("🚶 歩数データ権限結果: \(success ? "✅ 許可" : "❌ 拒否")")
                
                if let error = error {
                    print("❌ 権限エラー: \(error.localizedDescription)")
                }
                
                if success {
                    print("🚶 初回の歩数データを取得します...")
                    self.loadStepCount(for: self.selectedDate)
                    
                    // 月の歩数データも取得
                    if let monthInterval = self.calendar.dateInterval(of: .month, for: self.currentMonth) {
                        self.loadMonthStepCounts(startDate: monthInterval.start, endDate: monthInterval.end)
                    }
                    
                    // リアルタイム監視を開始
                    self.stepCountManager.startObservingSteps { steps in
                        print("🔄 歩数が更新されました: \(steps)歩")
                        if Calendar.current.isDateInToday(self.selectedDate) {
                            self.stepCount = steps
                            print("✅ UIを更新しました: \(steps)歩")
                        }
                    }
                } else {
                    print("⚠️ 歩数データの権限が拒否されたため、歩数表示は利用できません")
                }
            }
        }
    }
    
    // 選択日の歩数を読み込む
    private func loadStepCount(for date: Date) {
        guard stepCountAuthorized else {
            print("⚠️ 歩数データの権限がありません")
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        let dateString = formatter.string(from: date)
        
        print("🚶 \(dateString)の歩数を取得中...")
        
        stepCountManager.fetchStepCount(for: date) { steps, error in
            DispatchQueue.main.async {
                if let steps = steps {
                    self.stepCount = steps
                    print("✅ 歩数データ取得成功: \(steps)歩")
                    print("✅ stepCount変数に設定: \(self.stepCount ?? 0)歩")
                    print("✅ stepCountAuthorized: \(self.stepCountAuthorized)")
                    print("✅ UIに表示されるはず: stepCountAuthorized && stepCount != nil = \(self.stepCountAuthorized && self.stepCount != nil)")
                } else if let error = error {
                    print("❌ 歩数取得エラー: \(error.localizedDescription)")
                    self.stepCount = nil
                } else {
                    print("ℹ️ \(dateString)の歩数データがありません（0歩またはデータなし）")
                    self.stepCount = 0 // データがない場合は0歩として表示
                }
            }
        }
    }
}

// 歩数表示ビュー
struct StepCountView: View {
    let stepCount: Double
    let primaryColor: Color
    
    // 歩数の評価
    private var evaluation: StepEvaluation {
        switch stepCount {
        case 0..<3000:
            return StepEvaluation(level: "もう少し", color: .gray, icon: "figure.walk", message: "軽い散歩はいかがですか？")
        case 3000..<5000:
            return StepEvaluation(level: "良いスタート", color: .blue, icon: "figure.walk", message: "いい調子です！")
        case 5000..<8000:
            return StepEvaluation(level: "順調", color: .green, icon: "figure.walk", message: "素晴らしい活動量です！")
        case 8000..<10000:
            return StepEvaluation(level: "とても良い", color: .orange, icon: "figure.walk.motion", message: "健康的な1日ですね！")
        default:
            return StepEvaluation(level: "最高", color: .yellow, icon: "star.fill", message: "驚異的な活動量です！")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: evaluation.icon)
                    .foregroundColor(evaluation.color)
                    .font(.system(size: 20))
                
                Text("今日の歩数")
                    .font(.headline)
                    .foregroundColor(primaryColor)
                
                Spacer()
                
                Text(evaluation.level)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(evaluation.color.opacity(0.2))
                    .foregroundColor(evaluation.color)
                    .cornerRadius(8)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(stepCount.formatted(.number.precision(.fractionLength(0))))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(evaluation.color)
                
                Text("歩")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // プログレスバー（10,000歩を目標）
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        // プログレス
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [evaluation.color.opacity(0.7), evaluation.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: min(geometry.size.width * CGFloat(stepCount / 10000), geometry.size.width), height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text(evaluation.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if stepCount < 10000 {
                        Text("目標まであと\(Int(10000 - stepCount))歩")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("目標達成！🎉")
                            .font(.caption)
                            .foregroundColor(evaluation.color)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

// 歩数評価データ
struct StepEvaluation {
    let level: String
    let color: Color
    let icon: String
    let message: String
}

// コンパクトな歩数表示ビュー
struct CompactStepCountView: View {
    let stepCount: Double
    let primaryColor: Color
    
    // 歩数の評価
    private var evaluation: StepEvaluation {
        switch stepCount {
        case 0..<3000:
            return StepEvaluation(level: "もう少し", color: .gray, icon: "figure.walk", message: "軽い散歩はいかがですか？")
        case 3000..<5000:
            return StepEvaluation(level: "良いスタート", color: .blue, icon: "figure.walk", message: "いい調子です！")
        case 5000..<8000:
            return StepEvaluation(level: "順調", color: .green, icon: "figure.walk", message: "素晴らしい活動量です！")
        case 8000..<10000:
            return StepEvaluation(level: "とても良い", color: .orange, icon: "figure.walk.motion", message: "健康的な1日ですね！")
        default:
            return StepEvaluation(level: "最高", color: .yellow, icon: "star.fill", message: "驚異的な活動量です！")
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // アイコン
            Image(systemName: evaluation.icon)
                .foregroundColor(evaluation.color)
                .font(.system(size: 20))
            
            // 歩数表示
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(stepCount.formatted(.number.precision(.fractionLength(0))))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(evaluation.color)
                Text("歩")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // プログレスバー（コンパクト）
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    // プログレス
                    RoundedRectangle(cornerRadius: 2)
                        .fill(evaluation.color)
                        .frame(width: min(geometry.size.width * CGFloat(stepCount / 10000), geometry.size.width), height: 4)
                }
            }
            .frame(height: 4)
            
            // 評価レベル
            Text(evaluation.level)
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(evaluation.color.opacity(0.2))
                .foregroundColor(evaluation.color)
                .cornerRadius(4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

// カレンダービュー
struct CalendarView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let primaryColor: Color
    let hasRecordByDate: Set<String>
    let hasFullChargeByDate: Set<String>
    let stepCountByDate: [String: Double]
    let isSleepDeprivedByDate: [String: Bool]
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["日", "月", "火", "水", "木", "金", "土"]
    
    var body: some View {
        VStack(spacing: 12) {
            // 月の切り替えヘッダー
            HStack {
                Button(action: {
                    changeMonth(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(primaryColor)
                        .frame(width: 40, height: 40)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(primaryColor)
                
                Spacer()
                
                Button(action: {
                    changeMonth(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(primaryColor)
                        .frame(width: 40, height: 40)
                }
            }
            .padding(.horizontal, 8)
            
            // 曜日ヘッダー
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(day == "日" ? .red : day == "土" ? .blue : primaryColor)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            
            // 縦スクロール可能、先週と今週をメインに表示
            let allWeeks = getAllWeeksInMonth()
            let lastWeekIndex = getLastWeekIndex()
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 24) {
                        ForEach(0..<allWeeks.count, id: \.self) { index in
                            WeekRow(
                                week: allWeeks[index],
                                selectedDate: $selectedDate,
                                currentMonth: currentMonth,
                                primaryColor: primaryColor,
                                hasRecordByDate: hasRecordByDate,
                                hasFullChargeByDate: hasFullChargeByDate,
                                stepCountByDate: stepCountByDate,
                                isSleepDeprivedByDate: isSleepDeprivedByDate
                            )
                            .id(index)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .frame(maxHeight: .infinity)
                .onAppear {
                    // 先週にスクロール（先週と今週が表示される）
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(lastWeekIndex, anchor: .top)
                        }
                    }
                }
                .onChange(of: currentMonth) { oldValue, newValue in
                    // 月が変わったら先週にスクロール
                    let targetIndex = getLastWeekIndex()
                    withAnimation {
                        proxy.scrollTo(targetIndex, anchor: .top)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
    }
    
    // 月と年の文字列
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: currentMonth)
    }
    
    // 月を変更
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    // 先週のインデックスを取得
    private func getLastWeekIndex() -> Int {
        let allWeeks = getAllWeeksInMonth()
        let today = Date()
        
        // 今週のインデックスを探す
        for (index, week) in allWeeks.enumerated() {
            if week.dates.contains(where: { date in
                guard let date = date else { return false }
                return calendar.isDate(date, inSameDayAs: today)
            }) {
                // 先週のインデックスを返す（最低0）
                return max(0, index - 1)
            }
        }
        
        return 0
    }
    
    // 月内の全ての週を取得
    private func getAllWeeksInMonth() -> [WeekData] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var weeks: [WeekData] = []
        var currentDate = monthFirstWeek.start
        
        // 6週間分のカレンダーを作成
        for _ in 0..<6 {
            var weekDates: [Date?] = []
            var hasCurrentMonthDate = false
            
            for _ in 0..<7 {
                weekDates.append(currentDate)
                if calendar.isDate(currentDate, equalTo: currentMonth, toGranularity: .month) {
                    hasCurrentMonthDate = true
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            
            // 現在の月の日付が含まれている週のみ追加
            if hasCurrentMonthDate {
                weeks.append(WeekData(dates: weekDates))
            }
        }
        
        return weeks
    }
}

// 週のデータ構造
struct WeekData: Hashable {
    let dates: [Date?]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(dates.compactMap { $0?.timeIntervalSince1970 })
    }
}

// 週の行
struct WeekRow: View {
    let week: WeekData
    @Binding var selectedDate: Date
    let currentMonth: Date
    let primaryColor: Color
    let hasRecordByDate: Set<String>
    let hasFullChargeByDate: Set<String>
    let stepCountByDate: [String: Double]
    let isSleepDeprivedByDate: [String: Bool]
    
    private let calendar = Calendar.current
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                if let date = week.dates[index] {
                    DayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(date),
                        isInCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                        primaryColor: primaryColor,
                        hasRecord: hasRecordForDate(date),
                        hasFullCharge: hasFullChargeForDate(date),
                        hasHighStepCount: hasHighStepCountForDate(date),
                        isSleepDeprived: isSleepDeprivedForDate(date)
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Color.clear
                        .frame(width: 52, height: 52)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func hasRecordForDate(_ date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let dateKey = formatter.string(from: date)
        return hasRecordByDate.contains(dateKey)
    }
    
    private func hasFullChargeForDate(_ date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let dateKey = formatter.string(from: date)
        return hasFullChargeByDate.contains(dateKey)
    }
    
    private func hasHighStepCountForDate(_ date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let dateKey = formatter.string(from: date)
        
        if let steps = stepCountByDate[dateKey] {
            return steps >= 5000
        }
        return false
    }
    
    private func isSleepDeprivedForDate(_ date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let dateKey = formatter.string(from: date)
        
        return isSleepDeprivedByDate[dateKey] == true
    }
}

// 日付セル
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isInCurrentMonth: Bool
    let primaryColor: Color
    let hasRecord: Bool
    let hasFullCharge: Bool
    let hasHighStepCount: Bool
    let isSleepDeprived: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 18, weight: isSelected ? .bold : .regular))
                .foregroundColor(textColor)
                .frame(width: 52, height: 52)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isToday && !isSelected ? primaryColor : Color.clear, lineWidth: 2)
                )
            
            // 記録インジケーター
            HStack(spacing: 2) {
                if hasRecord {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                }
                if hasFullCharge {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                }
                if hasHighStepCount {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                }
                if isSleepDeprived {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 8)
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        }
        
        // 他の月の日付は薄く表示
        if !isInCurrentMonth {
            return Color.gray.opacity(0.3)
        }
        
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 1 { // 日曜日
            return .red
        } else if weekday == 7 { // 土曜日
            return .blue
        }
        return .primary
    }
    
    private var backgroundColor: Color {
        isSelected ? primaryColor : Color.clear
    }
}

#Preview {
    HomeScreen()
}

