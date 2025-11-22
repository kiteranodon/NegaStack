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
    
    // 全快完了アラート表示用
    @State private var showFullChargeAlert = false
    
    private let primaryColor = Color(hex: "007C8A")
    private let calendar = Calendar.current
    private let firebaseManager = FirebaseManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 上部：カレンダー（拡大）
                CalendarView(
                    currentMonth: $currentMonth,
                    selectedDate: $selectedDate,
                    primaryColor: primaryColor,
                    hasRecordByDate: hasRecordByDate,
                    hasFullChargeByDate: hasFullChargeByDate
                )
                .padding(.top, 16)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 下部：4つのボタンと下部メニュー
                VStack(spacing: 16) {
                    // 3つのボタン
                    GeometryReader { geometry in
                        let totalWidth = geometry.size.width - 40 - 16 // padding 20*2 + spacing 8*2
                        let buttonSize = min(totalWidth / 3, 70) // 基本サイズ（最大70）
                        let pencilButtonSize = buttonSize * 1.3 // えんぴつボタンは1.3倍
                        
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
                            .frame(width: buttonSize, height: buttonSize)
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
                            .frame(width: pencilButtonSize, height: pencilButtonSize)
                            
                            // 全快ボタン
                            Button(action: {
                                showFullChargeAlert = true
                            }) {
                                Text("全快")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: buttonSize, height: buttonSize)
                            .background(Color(hex: "69b076"))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
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
        .fullScreenCover(isPresented: $showLogJournal) {
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
                    case .failure(let error):
                        print("❌ 保存エラー: \(error.localizedDescription)")
                    }
                }
            }
        } message: {
            Text("よく休めましたか？辛いときはまた記録してみましょう！")
        }
        .onAppear {
            print("✅ HomeScreen表示完了")
            loadRecordData()
        }
        .onChange(of: currentMonth) { oldValue, newValue in
            loadRecordData()
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
            
            if case .success(let entries) = result {
                print("✅ HomeScreen: \(entries.count)件のジャーナルエントリを取得")
                for entry in entries {
                    journalDates.insert(entry.dateKey)
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
                    print("📊 🔵 記録: \(journalDates.sorted())")
                    print("📊 🟢 全快: \(fullChargeDates.sorted())")
                }
            }
        }
    }
}

// カレンダービュー
struct CalendarView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let primaryColor: Color
    let hasRecordByDate: Set<String>
    let hasFullChargeByDate: Set<String>
    
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
                                hasFullChargeByDate: hasFullChargeByDate
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
                        hasFullCharge: hasFullChargeForDate(date)
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

