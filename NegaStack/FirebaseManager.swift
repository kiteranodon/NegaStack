//
//  FirebaseManager.swift
//  NegaStack
//
//  Created by 千田海生 on 2025/11/21.
//

import Foundation
import FirebaseFirestore
import Combine

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    private init() {
        print("🔥 FirebaseManager initialized")
    }
    
    // ジャーナルエントリを保存
    func saveJournalEntry(_ entry: JournalEntry, completion: @escaping (Result<Void, Error>) -> Void) {
        // ユーザーIDベースのコレクション（将来的に認証を追加する場合）
        // 今は固定のユーザーIDを使用
        let userId = "default_user" // 後で Auth.auth().currentUser?.uid に変更可能
        
        print("📝 Firebaseに保存開始...")
        print("   日付キー: \(entry.dateKey)")
        print("   エントリID: \(entry.id)")
        
        // 日毎のドキュメント構造: users/{userId}/journals/{dateKey}/entries/{entryId}
        let docRef = db.collection("users")
            .document(userId)
            .collection("journals")
            .document(entry.dateKey)
            .collection("entries")
            .document(entry.id)
        
        docRef.setData(entry.toDictionary()) { error in
            if let error = error {
                print("❌ Firebase保存エラー: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("✅ Firebaseに保存成功!")
                print("   パス: users/\(userId)/journals/\(entry.dateKey)/entries/\(entry.id)")
                completion(.success(()))
            }
        }
    }
    
    // 特定の日のエントリを取得
    func getEntriesForDate(_ date: Date, completion: @escaping (Result<[JournalEntry], Error>) -> Void) {
        let userId = "default_user"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let dateKey = formatter.string(from: date)
        
        print("📖 \(dateKey)のエントリを取得中...")
        
        db.collection("users")
            .document(userId)
            .collection("journals")
            .document(dateKey)
            .collection("entries")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 取得エラー: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📭 エントリが見つかりませんでした")
                    completion(.success([]))
                    return
                }
                
                let entries = documents.compactMap { doc -> JournalEntry? in
                    return JournalEntry(dictionary: doc.data())
                }
                
                print("✅ \(entries.count)件のエントリを取得しました")
                completion(.success(entries))
            }
    }
    
    // 日付範囲でエントリを取得
    func getEntriesForDateRange(startDate: Date, endDate: Date, completion: @escaping (Result<[JournalEntry], Error>) -> Void) {
        print("📖 期間(\(startDate) ~ \(endDate))のエントリを取得中...")
        
        // collectionGroupは全てのentriesサブコレクションを横断検索
        db.collectionGroup("entries")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 取得エラー: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📭 エントリが見つかりませんでした")
                    completion(.success([]))
                    return
                }
                
                let entries = documents.compactMap { doc -> JournalEntry? in
                    return JournalEntry(dictionary: doc.data())
                }
                
                print("✅ \(entries.count)件のエントリを取得しました")
                completion(.success(entries))
            }
    }
    
    // すべてのエントリを取得（最新順）
    func getAllEntries(limit: Int = 50, completion: @escaping (Result<[JournalEntry], Error>) -> Void) {
        print("📖 すべてのエントリを取得中（最大\(limit)件）...")
        
        // collectionGroupは全てのentriesサブコレクションを横断検索
        db.collectionGroup("entries")
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 取得エラー: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📭 エントリが見つかりませんでした")
                    completion(.success([]))
                    return
                }
                
                let entries = documents.compactMap { doc -> JournalEntry? in
                    return JournalEntry(dictionary: doc.data())
                }
                
                print("✅ \(entries.count)件のエントリを取得しました")
                completion(.success(entries))
            }
    }
    
    // エントリを削除
    func deleteEntry(_ entry: JournalEntry, completion: @escaping (Result<Void, Error>) -> Void) {
        let userId = "default_user"
        
        print("🗑 エントリを削除中...")
        
        let docRef = db.collection("users")
            .document(userId)
            .collection("journals")
            .document(entry.dateKey)
            .collection("entries")
            .document(entry.id)
        
        docRef.delete { error in
            if let error = error {
                print("❌ 削除エラー: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("✅ エントリを削除しました")
                completion(.success(()))
            }
        }
    }
}

