//
//  JournalEntry.swift
//  NegaStack
//
//  Created by 千田海生 on 2025/11/21.
//

import Foundation
import FirebaseFirestore
import SwiftUI

// Firestoreに保存するためのデータモデル
struct JournalEntry: Codable {
    var id: String = UUID().uuidString
    var date: Date
    var negativeFeeling: String
    var emotions: [EmotionEntry]
    var thinkings: [String]
    var isSleepDeprived: Bool? // 寝不足かどうか
    var nextTask: String // 今からしなければいけないこと
    var taskDurationMinutes: Int // 所要時間（分単位）
    var restActivity: String
    var alarmTime: Date?
    var actionType: String // "rest" or "quickStart"
    
    struct EmotionEntry: Codable {
        let name: String
        let colorHex: String // Colorは直接保存できないのでHex文字列に変換
    }
    
    // FirestoreのドキュメントIDとして使う日付キー（YYYY-MM-DD形式）
    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }
    
    // Firestoreに保存する用のDictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "date": Timestamp(date: date),
            "negativeFeeling": negativeFeeling,
            "emotions": emotions.map { ["name": $0.name, "colorHex": $0.colorHex] },
            "thinkings": thinkings,
            "nextTask": nextTask,
            "taskDurationMinutes": taskDurationMinutes,
            "restActivity": restActivity,
            "actionType": actionType
        ]
        
        // オプショナルの値を適切に処理
        if let isSleepDeprived = isSleepDeprived {
            dict["isSleepDeprived"] = isSleepDeprived
        }
        
        if let alarmTime = alarmTime {
            dict["alarmTime"] = Timestamp(date: alarmTime)
        }
        
        return dict
    }
    
    // Firestoreのデータから初期化
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let timestamp = dictionary["date"] as? Timestamp,
              let negativeFeeling = dictionary["negativeFeeling"] as? String,
              let emotionsData = dictionary["emotions"] as? [[String: String]],
              let thinkings = dictionary["thinkings"] as? [String],
              let restActivity = dictionary["restActivity"] as? String,
              let actionType = dictionary["actionType"] as? String else {
            return nil
        }
        
        self.id = id
        self.date = timestamp.dateValue()
        self.negativeFeeling = negativeFeeling
        self.emotions = emotionsData.compactMap { data in
            guard let name = data["name"], let colorHex = data["colorHex"] else { return nil }
            return EmotionEntry(name: name, colorHex: colorHex)
        }
        self.thinkings = thinkings
        self.restActivity = restActivity
        self.actionType = actionType
        
        // nextTaskとtaskDurationMinutesはデフォルト値を設定（後方互換性のため）
        self.nextTask = dictionary["nextTask"] as? String ?? ""
        self.taskDurationMinutes = dictionary["taskDurationMinutes"] as? Int ?? 0
        
        self.isSleepDeprived = dictionary["isSleepDeprived"] as? Bool
        
        if let alarmTimestamp = dictionary["alarmTime"] as? Timestamp {
            self.alarmTime = alarmTimestamp.dateValue()
        }
    }
    
    // 通常の初期化
    init(date: Date = Date(),
         negativeFeeling: String,
         emotions: [EmotionEntry],
         thinkings: [String],
         isSleepDeprived: Bool?,
         nextTask: String,
         taskDurationMinutes: Int,
         restActivity: String,
         alarmTime: Date?,
         actionType: String) {
        self.date = date
        self.negativeFeeling = negativeFeeling
        self.emotions = emotions
        self.thinkings = thinkings
        self.isSleepDeprived = isSleepDeprived
        self.nextTask = nextTask
        self.taskDurationMinutes = taskDurationMinutes
        self.restActivity = restActivity
        self.alarmTime = alarmTime
        self.actionType = actionType
    }
}

// 全快完了データモデル
struct FullChargeEntry: Codable {
    var id: String = UUID().uuidString
    var date: Date
    var source: String // "startScreen" or "homeScreen"
    
    // FirestoreのドキュメントIDとして使う日付キー（YYYY-MM-DD形式）
    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }
    
    // Firestoreに保存する用のDictionary
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "date": Timestamp(date: date),
            "source": source,
            "type": "fullCharge"
        ]
    }
    
    // Firestoreのデータから初期化
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let timestamp = dictionary["date"] as? Timestamp,
              let source = dictionary["source"] as? String else {
            return nil
        }
        
        self.id = id
        self.date = timestamp.dateValue()
        self.source = source
    }
    
    // 通常の初期化
    init(date: Date = Date(), source: String) {
        self.date = date
        self.source = source
    }
}

// Color to Hex 変換用のextension
extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(format: "#%02X%02X%02X",
                     Int(r * 255),
                     Int(g * 255),
                     Int(b * 255))
    }
}

