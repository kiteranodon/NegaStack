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
    
    // 全快完了アラート表示用
    @State private var showFullChargeAlert = false
    
    private let primaryColor = Color(hex: "007C8A")
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 上半分：カレンダー
                    CalendarView(
                        currentMonth: $currentMonth,
                        selectedDate: $selectedDate,
                        primaryColor: primaryColor
                    )
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                    
                    // 4つのボタン
                    GeometryReader { geometry in
                        let totalWidth = geometry.size.width - 40 - 24 // padding 20*2 + spacing 8*3
                        let buttonSize = min(totalWidth / 4, 70) // 基本サイズ（最大70）
                        let pencilButtonSize = buttonSize * 1.3 // えんぴつボタンは1.3倍
                        
                        HStack(spacing: 8) {
                            // Last Timeボタン
                            Button(action: {
                                print("Last Time")
                            }) {
                                Text("Last Time")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(primaryColor)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(width: buttonSize, height: buttonSize)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(primaryColor, lineWidth: 2)
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
                    .padding(.top, 16)
                    
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
                    .padding(.top, 16)
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
        }
    }
}

// カレンダービュー
struct CalendarView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let primaryColor: Color
    
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
            
            // カレンダーグリッド
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(getAllDatesInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            primaryColor: primaryColor
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        // 空のセル
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
            .padding(.horizontal, 8)
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
    
    // 月の全ての日付を取得（空のセルも含む）
    private func getAllDatesInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var dates: [Date?] = []
        
        // 月の最初の週の開始日を取得
        var currentDate = monthFirstWeek.start
        
        // 6週間分のカレンダーを作成
        for _ in 0..<42 {
            if calendar.isDate(currentDate, equalTo: currentMonth, toGranularity: .month) {
                dates.append(currentDate)
            } else {
                dates.append(nil)
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
}

// 日付セル
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let primaryColor: Color
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .foregroundColor(textColor)
                .frame(width: 36, height: 36)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isToday && !isSelected ? primaryColor : Color.clear, lineWidth: 2)
                )
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
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

