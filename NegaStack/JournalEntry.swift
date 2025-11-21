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
    var usePhone: Bool?
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
            "restActivity": restActivity,
            "actionType": actionType
        ]
        
        // オプショナルの値を適切に処理
        if let usePhone = usePhone {
            dict["usePhone"] = usePhone
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
        
        self.usePhone = dictionary["usePhone"] as? Bool
        
        if let alarmTimestamp = dictionary["alarmTime"] as? Timestamp {
            self.alarmTime = alarmTimestamp.dateValue()
        }
    }
    
    // 通常の初期化
    init(date: Date = Date(),
         negativeFeeling: String,
         emotions: [EmotionEntry],
         thinkings: [String],
         usePhone: Bool?,
         restActivity: String,
         alarmTime: Date?,
         actionType: String) {
        self.date = date
        self.negativeFeeling = negativeFeeling
        self.emotions = emotions
        self.thinkings = thinkings
        self.usePhone = usePhone
        self.restActivity = restActivity
        self.alarmTime = alarmTime
        self.actionType = actionType
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

