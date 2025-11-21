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
    
    private let primaryColor = Color(hex: "007C8A")
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 上半分：カレンダー
                VStack {
                    CalendarView(
                        currentMonth: $currentMonth,
                        selectedDate: $selectedDate,
                        primaryColor: primaryColor
                    )
                    .padding(.top, 20)
                    .padding(.horizontal, 30)
                }
                .frame(maxHeight: .infinity)
                
                // 下半分
                VStack(spacing: 20) {
                    // 4つのボタン
                    GeometryReader { geometry in
                        let totalWidth = geometry.size.width - 60 - 24 // padding 30*2 + spacing 8*3
                        let buttonSize = totalWidth / 4 // 基本サイズ（1/4）
                        let pencilButtonSize = buttonSize * 1.3 // えんぴつボタンは1.3倍
                        
                        HStack(spacing: 8) {
                            // Last Timeボタン
                            Button(action: {
                                print("Last Time")
                            }) {
                                Text("Last Time")
                                    .font(.system(size: 14, weight: .semibold))
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
                                VStack(spacing: 6) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 32))
                                    Text("記録する")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(primaryColor)
                            }
                            .frame(width: pencilButtonSize, height: pencilButtonSize)
                            
                            // Quoteボタン
                            Button(action: {
                                print("Quote")
                            }) {
                                Text("Quote")
                                    .font(.system(size: 14, weight: .semibold))
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
                                print("全快")
                            }) {
                                Text("全快")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: buttonSize, height: buttonSize)
                            .background(Color(hex: "69b076"))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 30)
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 130)
                    .padding(.top, 20)
                    
                    // 下部メニュー（背景色付き）
                    VStack(spacing: 0) {
                        // 下部メニュー（3つのボタン）
                        HStack(spacing: 0) {
                            // Homeボタン
                            Button(action: {
                                print("Home")
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 24))
                                    Text("Home")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(primaryColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                            
                            // Stackボタン
                            Button(action: {
                                print("Stack")
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "square.stack.3d.up.fill")
                                        .font(.system(size: 24))
                                    Text("Stack")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(primaryColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                            
                            // Pillarボタン
                            Button(action: {
                                print("Pillar")
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "building.columns.fill")
                                        .font(.system(size: 24))
                                    Text("Pillar")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(primaryColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                        }
                        
                        Spacer()
                    }
                    .background(Color(hex: "FED5B0"))
                }
                .frame(maxHeight: .infinity)
                
                Spacer()
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
        VStack(spacing: 20) {
            // 月の切り替えヘッダー
            HStack {
                Button(action: {
                    changeMonth(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(primaryColor)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(primaryColor)
                
                Spacer()
                
                Button(action: {
                    changeMonth(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(primaryColor)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal)
            
            // 曜日ヘッダー
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(day == "日" ? .red : day == "土" ? .blue : primaryColor)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // カレンダーグリッド
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 12) {
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
                            .frame(height: 44)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
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
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(textColor)
                .frame(width: 44, height: 44)
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

