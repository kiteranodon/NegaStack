//
//  LogJournal.swift
//  NegaStack
//
//  Created by 千田海生 on 2025/11/21.
//

import SwiftUI
import UserNotifications

// 感情データ構造
struct EmotionData: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: EmotionData, rhs: EmotionData) -> Bool {
        lhs.name == rhs.name
    }
}

struct LogJournal: View {
    @Environment(\.dismiss) var dismiss
    @State private var negativeFeeling: String = ""
    @State private var selectedEmotions: [EmotionData] = []
    @State private var customEmotion: String = ""
    @State private var selectedColor: Color = Color(hex: "A8BA8F")
    @State private var showColorPicker: Bool = false
    @State private var selectedThinkings: [String] = []
    @State private var customThinking: String = ""
    @State private var usePhone: Bool? = nil // true: 使う, false: 使わない, nil: 未選択
    @State private var restActivity: String = ""
    @State private var alarmTime: Date = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
    @State private var showTimerPicker: Bool = false
    @State private var showRestStartedAlert: Bool = false
    @State private var showQuickStartAlert: Bool = false
    @State private var shouldDismiss: Bool = false
    @FocusState private var isTextEditorFocused: Bool
    
    // HomeScreenへの遷移用クロージャー
    var onQuickStart: (() -> Void)? = nil
    var onRestStarted: (() -> Void)? = nil
    
    // Firebase管理
    private let firebaseManager = FirebaseManager.shared
    
    private let primaryColor = Color(hex: "007C8A")
    
    // 感情データ
    private let fineEmotions = ["スッキリ", "ドキドキ", "安心", "穏やか", "普通", "退屈", "モヤモヤ", "緊張"]
    private let negativeEmotions = ["不安", "悲しい", "疲れた", "後悔", "恐れる", "イライラ", "怒り", "嫌い"]
    
    // 「何について」データ
    private let personThinkings = ["自分", "友達", "家族", "ペット"]
    private let lifeThinkings = ["仕事", "バイト", "勉強", "お金", "恋愛", "家事", "健康", "就職"]
    private let hobbyThinkings = ["食", "本", "音楽", "旅行", "美容", "ゲーム", "スポーツ", "お酒"]
    private let othersThinkings = ["学校", "交通機関", "その他"]
    
    // カラーパレット
    private let colorPalette: [Color] = [
        Color(hex: "C85A54"), Color(hex: "D97C6E"), Color(hex: "E09E88"),
        Color(hex: "E8B87A"), Color(hex: "D4C48E"), Color(hex: "BFD090"),
        Color(hex: "A8BA8F"), Color(hex: "8FAA92"), Color(hex: "7FA089"),
        Color(hex: "7FA497"), Color(hex: "7FA8A5"), Color(hex: "7FA8B3"),
        Color(hex: "7FA8C3"), Color(hex: "8DADC8"), Color(hex: "9BB3CD"),
        Color(hex: "A9B9D2")
    ]
    
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
                        
                        // 選択済み感情表示
                        if !selectedEmotions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("選択した気持ち (\(selectedEmotions.count)/3)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 30)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(selectedEmotions) { emotion in
                                            SelectedEmotionChip(
                                                emotion: emotion,
                                                onRemove: {
                                                    removeEmotion(emotion)
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 30)
                                }
                            }
                            .padding(.bottom, 10)
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
                        VStack(spacing: 16) {
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
                                .onChange(of: customEmotion) { oldValue, newValue in
                                    if newValue.count > 4 {
                                        customEmotion = String(newValue.prefix(4))
                                    }
                                }
                                
                                // 色選択ボタン
                                Button(action: {
                                    showColorPicker.toggle()
                                }) {
                                    Circle()
                                        .fill(selectedColor)
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                        )
                                }
                                
                                Button(action: {
                                    addCustomEmotion()
                                }) {
                                    Text("追加")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(primaryColor)
                                }
                            }
                            .padding(.horizontal, 30)
                            
                            // カラーパレット
                            if showColorPicker {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("色を選択")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 30)
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 8), spacing: 12) {
                                        ForEach(colorPalette.indices, id: \.self) { index in
                                            Button(action: {
                                                selectedColor = colorPalette[index]
                                                showColorPicker = false
                                            }) {
                                                Circle()
                                                    .fill(colorPalette[index])
                                                    .frame(width: 36, height: 36)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(selectedColor == colorPalette[index] ? primaryColor : Color.clear, lineWidth: 3)
                                                    )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 30)
                                }
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 30)
                    
                    // 「何について？」セクション
                    VStack(spacing: 20) {
                        // タイトル
                        VStack(spacing: 8) {
                            Text("何について？")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(primaryColor)
                            Text("必須。3つまで")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        // 選択済み項目表示
                        if !selectedThinkings.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("選択した項目 (\(selectedThinkings.count)/3)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 30)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(selectedThinkings, id: \.self) { thinking in
                                            SelectedThinkingChip(
                                                thinking: thinking,
                                                onRemove: {
                                                    removeThinking(thinking)
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 30)
                                }
                            }
                            .padding(.bottom, 10)
                        }
                        
                        // Person
                        ThinkingSection(
                            title: "Person",
                            thinkings: personThinkings,
                            selectedThinkings: $selectedThinkings
                        )
                        
                        Divider()
                            .padding(.horizontal, 30)
                        
                        // Life
                        ThinkingSection(
                            title: "Life",
                            thinkings: lifeThinkings,
                            selectedThinkings: $selectedThinkings
                        )
                        
                        Divider()
                            .padding(.horizontal, 30)
                        
                        // Hobby
                        ThinkingSection(
                            title: "Hobby",
                            thinkings: hobbyThinkings,
                            selectedThinkings: $selectedThinkings
                        )
                        
                        Divider()
                            .padding(.horizontal, 30)
                        
                        // Others
                        ThinkingSection(
                            title: "Others",
                            thinkings: othersThinkings,
                            selectedThinkings: $selectedThinkings
                        )
                        
                        // 自由入力セクション
                        HStack(spacing: 12) {
                            TextField("10文字まで自由入力", text: $customThinking)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: customThinking) { oldValue, newValue in
                                if newValue.count > 10 {
                                    customThinking = String(newValue.prefix(10))
                                }
                            }
                            
                            Button(action: {
                                addCustomThinking()
                            }) {
                                Text("追加")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(primaryColor)
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 30)
                    
                    // 「どうやって休む？」セクション
                    VStack(spacing: 20) {
                        // タイトル
                        Text("どうやって休む？")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(primaryColor)
                        
                        // スマホの使用選択
                        VStack(alignment: .leading, spacing: 12) {
                            Text("スマホは？")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 30)
                            
                            HStack(spacing: 16) {
                                // 使うボタン
                                Button(action: {
                                    usePhone = true
                                }) {
                                    HStack {
                                        Image(systemName: usePhone == true ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 24))
                                        Text("使う")
                                            .font(.system(size: 18, weight: .medium))
                                    }
                                    .foregroundColor(usePhone == true ? primaryColor : .gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(usePhone == true ? primaryColor.opacity(0.1) : Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(usePhone == true ? primaryColor : Color.gray.opacity(0.3), lineWidth: 2)
                                    )
                                }
                                
                                // 使わないボタン
                                Button(action: {
                                    usePhone = false
                                }) {
                                    HStack {
                                        Image(systemName: usePhone == false ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 24))
                                        Text("使わない")
                                            .font(.system(size: 18, weight: .medium))
                                    }
                                    .foregroundColor(usePhone == false ? primaryColor : .gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(usePhone == false ? primaryColor.opacity(0.1) : Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(usePhone == false ? primaryColor : Color.gray.opacity(0.3), lineWidth: 2)
                                    )
                                }
                            }
                            .padding(.horizontal, 30)
                        }
                        
                        // 何をして休む？
                        VStack(alignment: .leading, spacing: 12) {
                            Text(usePhone == true ? "スマホで何をして休む？" : usePhone == false ? "何をして休む？" : "何をして休む？")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 30)
                            
                            TextField("例: YouTubeを見る、音楽を聴く、散歩する", text: $restActivity)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.horizontal, 30)
                        }
                        
                        // アラーム時間設定
                        VStack(alignment: .leading, spacing: 12) {
                            Text("いつまで休む？")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 30)
                            
                            Button(action: {
                                showTimerPicker.toggle()
                            }) {
                                HStack {
                                    Image(systemName: "alarm.fill")
                                        .font(.system(size: 20))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(formatAlarmDate(alarmTime))
                                            .font(.system(size: 18, weight: .semibold))
                                        Text(formatAlarmTime(alarmTime))
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    Spacer()
                                    Image(systemName: showTimerPicker ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 16))
                                }
                                .foregroundColor(primaryColor)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(primaryColor, lineWidth: 2)
                                )
                            }
                            .padding(.horizontal, 30)
                            
                            // 日時ピッカー
                            if showTimerPicker {
                                VStack(spacing: 16) {
                                    DatePicker("", selection: $alarmTime, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                        .datePickerStyle(.graphical)
                                        .labelsHidden()
                                        .environment(\.locale, Locale(identifier: "ja_JP"))
                                    
                                    // 現在時刻からの差分を表示
                                    let timeInterval = alarmTime.timeIntervalSince(Date())
                                    let hours = Int(timeInterval) / 3600
                                    let minutes = (Int(timeInterval) % 3600) / 60
                                    
                                    if timeInterval > 0 {
                                        Text("あと\(hours > 0 ? "\(hours)時間" : "")\(minutes)分")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Button(action: {
                                        showTimerPicker = false
                                    }) {
                                        Text("決定")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(primaryColor)
                                            .cornerRadius(12)
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                .padding(.horizontal, 30)
                            }
                        }
                        
                        // ボタン2つ
                        HStack(spacing: 12) {
                            // すぐ動き出すボタン
                            Button(action: {
                                // Firebaseにデータを保存
                                saveToFirebase(actionType: "quickStart")
                                showQuickStartAlert = true
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 20))
                                    Text("すぐ動き出す")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "FAA755"))
                                .cornerRadius(12)
                            }
                            
                            // 休憩開始ボタン
                            Button(action: {
                                startRestTimer()
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 20))
                                    Text("休憩を始める")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    canStartRest() ? Color(hex: "69b076") : Color.gray
                                )
                                .cornerRadius(12)
                            }
                            .disabled(!canStartRest())
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 50)
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
        .alert("休憩が始まりました", isPresented: $showRestStartedAlert) {
            Button("OK") {
                // HomeScreenに遷移
                if let onRestStarted = onRestStarted {
                    onRestStarted()
                }
                dismiss()
            }
        } message: {
            Text("設定した時刻にアラームでお知らせします。\nゆっくり休んでくださいね。")
        }
        .alert("くれぐれも無理はしないでね", isPresented: $showQuickStartAlert) {
            Button("OK") {
                // HomeScreenに遷移
                print("🏠 OKボタンがタップされました")
                onQuickStart?()
                dismiss()
            }
        } message: {
            Text("あなたの体調を第一に考えてください。")
        }
    }
    
    // 感情を削除
    private func removeEmotion(_ emotion: EmotionData) {
        selectedEmotions.removeAll { $0.name == emotion.name }
    }
    
    // カスタム感情を追加
    private func addCustomEmotion() {
        if !customEmotion.isEmpty && selectedEmotions.count < 3 {
            let newEmotion = EmotionData(name: customEmotion, color: selectedColor)
            selectedEmotions.append(newEmotion)
            customEmotion = ""
            showColorPicker = false
        }
    }
    
    // 「何について」を削除
    private func removeThinking(_ thinking: String) {
        selectedThinkings.removeAll { $0 == thinking }
    }
    
    // カスタム「何について」を追加
    private func addCustomThinking() {
        if !customThinking.isEmpty && selectedThinkings.count < 3 {
            selectedThinkings.append(customThinking)
            customThinking = ""
        }
    }
    
    // 休憩開始可能かチェック
    private func canStartRest() -> Bool {
        return !negativeFeeling.isEmpty &&
               selectedEmotions.count > 0 &&
               selectedThinkings.count > 0 &&
               usePhone != nil &&
               !restActivity.isEmpty
    }
    
    // アラーム時間をフォーマット（日付）
    private func formatAlarmDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日(E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    // アラーム時間をフォーマット（時刻）
    private func formatAlarmTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    // 休憩タイマーを開始
    private func startRestTimer() {
        print("=== 休憩開始 ===")
        print("現在時刻: \(Date())")
        print("アラーム時刻: \(alarmTime)")
        
        // Firebaseにデータを保存
        saveToFirebase(actionType: "rest")
        
        // 既存の通知をキャンセル
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
        
        // 通知権限を確認してリクエスト
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("通知設定状態: \(settings.authorizationStatus.rawValue)")
            
            if settings.authorizationStatus == .authorized {
                // すでに許可されている場合はそのまま通知をスケジュール
                DispatchQueue.main.async {
                    self.scheduleRestNotification()
                    // アラートを表示
                    self.showRestStartedAlert = true
                }
            } else if settings.authorizationStatus == .notDetermined {
                // 未決定の場合は権限をリクエスト
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    print("通知権限リクエスト結果: \(granted)")
                    if let error = error {
                        print("権限リクエストエラー: \(error.localizedDescription)")
                    }
                    
                    DispatchQueue.main.async {
                        if granted {
                            self.scheduleRestNotification()
                        } else {
                            print("通知権限が拒否されました")
                        }
                        // アラートを表示
                        self.showRestStartedAlert = true
                    }
                }
            } else {
                print("通知権限がありません。設定アプリから許可してください。")
                // アラートを表示
                DispatchQueue.main.async {
                    self.showRestStartedAlert = true
                }
            }
        }
        
        // TODO: 画面遷移や状態管理を追加
        print("ネガティブな気持ち: \(negativeFeeling)")
        print("選択した感情: \(selectedEmotions.map { $0.name })")
        print("何について: \(selectedThinkings)")
        print("スマホ使用: \(usePhone == true ? "使う" : "使わない")")
        print("休憩方法: \(restActivity)")
    }
    
    // 休憩終了の通知をスケジュール
    private func scheduleRestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "休憩時間終了"
        content.body = "お疲れ様でした！気持ちは少し楽になりましたか？"
        content.sound = .defaultCritical // より確実に音が鳴るように変更
        content.badge = 1
        
        // 現在時刻からアラーム時刻までの秒数を計算
        let timeInterval = alarmTime.timeIntervalSince(Date())
        
        print("通知までの時間: \(timeInterval)秒 (\(Int(timeInterval/60))分)")
        
        // 未来の時刻の場合のみ通知をスケジュール
        if timeInterval > 0 {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(identifier: "restTimer", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ 通知エラー: \(error.localizedDescription)")
                } else {
                    print("✅ アラームが設定されました!")
                    print("   日時: \(self.formatAlarmDate(self.alarmTime)) \(self.formatAlarmTime(self.alarmTime))")
                    
                    // 設定された通知を確認
                    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                        print("📋 保留中の通知数: \(requests.count)")
                        for request in requests {
                            if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                                print("   - ID: \(request.identifier), 残り: \(Int(trigger.timeInterval))秒")
                            }
                        }
                    }
                }
            }
        } else {
            print("❌ エラー: 選択された時刻が過去です")
        }
    }
    
    // Firebaseにデータを保存
    private func saveToFirebase(actionType: String) {
        print("💾 Firebase保存処理開始（actionType: \(actionType)）")
        
        // EmotionDataをJournalEntry.EmotionEntryに変換
        let emotionEntries = selectedEmotions.map { emotion -> JournalEntry.EmotionEntry in
            let colorHex = emotion.color.toHex()
            return JournalEntry.EmotionEntry(name: emotion.name, colorHex: colorHex)
        }
        
        // JournalEntryを作成
        let entry = JournalEntry(
            date: Date(),
            negativeFeeling: negativeFeeling,
            emotions: emotionEntries,
            thinkings: selectedThinkings,
            usePhone: usePhone,
            restActivity: restActivity,
            alarmTime: actionType == "rest" ? alarmTime : nil,
            actionType: actionType
        )
        
        // Firebaseに保存
        firebaseManager.saveJournalEntry(entry) { result in
            switch result {
            case .success:
                print("✅ ジャーナルエントリをFirebaseに保存しました")
                print("   日付: \(entry.dateKey)")
                print("   気持ち: \(emotionEntries.map { $0.name }.joined(separator: ", "))")
                print("   何について: \(selectedThinkings.joined(separator: ", "))")
            case .failure(let error):
                print("❌ Firebase保存エラー: \(error.localizedDescription)")
            }
        }
    }
}

// 選択済み感情チップ
struct SelectedEmotionChip: View {
    let emotion: EmotionData
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(emotion.color.opacity(0.8))
                .frame(width: 24, height: 24)
            
            Text(emotion.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(emotion.color, lineWidth: 2)
        )
    }
}

// 選択済み「何について」チップ
struct SelectedThinkingChip: View {
    let thinking: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text(thinking)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
        )
    }
}

// 感情セクション
struct EmotionSection: View {
    let title: String
    let emotions: [String]
    @Binding var selectedEmotions: [EmotionData]
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
                    let emotionColor = interpolateColor(
                        start: colorStart,
                        end: colorEnd,
                        fraction: Double(index) / Double(emotions.count - 1)
                    )
                    EmotionButton(
                        emotion: emotions[index],
                        isSelected: selectedEmotions.contains(where: { $0.name == emotions[index] }),
                        color: emotionColor,
                        action: {
                            toggleEmotion(emotions[index], color: emotionColor)
                        }
                    )
                }
            }
            .padding(.horizontal, 30)
        }
    }
    
    private func toggleEmotion(_ emotion: String, color: Color) {
        if let index = selectedEmotions.firstIndex(where: { $0.name == emotion }) {
            selectedEmotions.remove(at: index)
        } else if selectedEmotions.count < 3 {
            selectedEmotions.append(EmotionData(name: emotion, color: color))
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

// 「何について」セクション
struct ThinkingSection: View {
    let title: String
    let thinkings: [String]
    @Binding var selectedThinkings: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // セクションタイトル
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.leading, 30)
            
            // ボタングリッド
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 20) {
                ForEach(thinkings, id: \.self) { thinking in
                    ThinkingButton(
                        thinking: thinking,
                        isSelected: selectedThinkings.contains(thinking),
                        action: {
                            toggleThinking(thinking)
                        }
                    )
                }
            }
            .padding(.horizontal, 30)
        }
    }
    
    private func toggleThinking(_ thinking: String) {
        if selectedThinkings.contains(thinking) {
            selectedThinkings.removeAll { $0 == thinking }
        } else if selectedThinkings.count < 3 {
            selectedThinkings.append(thinking)
        }
    }
}

// 「何について」ボタン
struct ThinkingButton: View {
    let thinking: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: "E5E5E5"))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(thinking)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                                .multilineTextAlignment(.center)
                                .padding(8)
                        )
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

