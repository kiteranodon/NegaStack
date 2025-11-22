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
    private lazy var db: Firestore = {
        print("🔥 Firestoreインスタンスを取得")
        return Firestore.firestore()
    }()
    
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
        print("   保存先パス: users/\(userId)/journals/\(entry.dateKey)/entries/\(entry.id)")
        
        // 日毎のドキュメント構造: users/{userId}/journals/{dateKey}/entries/{entryId}
        let docRef = db.collection("users")
            .document(userId)
            .collection("journals")
            .document(entry.dateKey)
            .collection("entries")
            .document(entry.id)
        
        let data = entry.toDictionary()
        print("   保存データのキー: \(data.keys.joined(separator: ", "))")
        
        docRef.setData(data) { error in
            if let error = error {
                print("❌ Firebase保存エラー: \(error.localizedDescription)")
                print("   エラーコード: \((error as NSError).code)")
                print("   エラードメイン: \((error as NSError).domain)")
                completion(.failure(error))
            } else {
                print("✅ Firebaseに保存成功!")
                print("   完全パス: \(docRef.path)")
                
                // 保存直後に確認読み込み
                docRef.getDocument { snapshot, readError in
                    if let readError = readError {
                        print("⚠️ 保存後の確認読み込みエラー: \(readError.localizedDescription)")
                    } else if let snapshot = snapshot, snapshot.exists {
                        print("✅ 保存確認OK: データが存在します")
                    } else {
                        print("⚠️ 保存確認NG: データが見つかりません")
                    }
                }
                
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
        let userId = "default_user"
        print("📖 すべてのエントリを取得中（最大\(limit)件）...")
        print("   方法1: collectionGroupクエリを試行")
        
        // まずcollectionGroupクエリを試す
        db.collectionGroup("entries")
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ collectionGroupクエリエラー: \(error.localizedDescription)")
                    
                    // collectionGroupが失敗した場合、代替方法を試す
                    if error.localizedDescription.contains("index") || error.localizedDescription.contains("requires an index") {
                        print("⚠️ Firestoreインデックスが必要です")
                        print("   方法2: journalsコレクションから日付ベースで取得を試みます...")
                        self.getAllEntriesAlternative(userId: userId, limit: limit, completion: completion)
                    } else {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📭 エントリが見つかりませんでした（snapshotがnil）")
                    completion(.success([]))
                    return
                }
                
                print("📦 Firestoreから\(documents.count)件のドキュメントを取得")
                
                if documents.isEmpty {
                    print("⚠️ ドキュメントは0件です")
                } else {
                    print("   最初のドキュメントのデータ:")
                    if let firstDoc = documents.first {
                        print("   - Document ID: \(firstDoc.documentID)")
                        print("   - Path: \(firstDoc.reference.path)")
                        print("   - Data keys: \(firstDoc.data().keys.joined(separator: ", "))")
                    }
                }
                
                let entries = documents.compactMap { doc -> JournalEntry? in
                    let entry = JournalEntry(dictionary: doc.data())
                    if entry == nil {
                        print("⚠️ パース失敗: \(doc.documentID)")
                        print("   データ: \(doc.data())")
                    }
                    return entry
                }
                
                print("✅ \(entries.count)件のエントリをパースしました")
                completion(.success(entries))
            }
    }
    
    // 代替方法：日付ドキュメントを列挙してエントリを取得
    private func getAllEntriesAlternative(userId: String, limit: Int, completion: @escaping (Result<[JournalEntry], Error>) -> Void) {
        print("🔄 代替方法でエントリを取得中...")
        print("   パス: users/\(userId)/journals")
        
        // journalsコレクションの全ドキュメント（日付キー）を取得
        db.collection("users")
            .document(userId)
            .collection("journals")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ journals取得エラー: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let journalDocs = snapshot?.documents else {
                    print("📭 journalsドキュメントが見つかりませんでした（snapshotがnil）")
                    completion(.success([]))
                    return
                }
                
                print("📅 \(journalDocs.count)個の日付ドキュメントを発見")
                if !journalDocs.isEmpty {
                    print("   日付ドキュメント一覧:")
                    for doc in journalDocs {
                        print("   - \(doc.documentID) (path: \(doc.reference.path))")
                    }
                }
                
                var allEntries: [JournalEntry] = []
                let group = DispatchGroup()
                
                // 各日付のentriesサブコレクションを取得
                for journalDoc in journalDocs {
                    group.enter()
                    self.db.collection("users")
                        .document(userId)
                        .collection("journals")
                        .document(journalDoc.documentID)
                        .collection("entries")
                        .getDocuments { entriesSnapshot, entriesError in
                            if let entriesError = entriesError {
                                print("❌ entries取得エラー [\(journalDoc.documentID)]: \(entriesError.localizedDescription)")
                            } else if let entriesDocs = entriesSnapshot?.documents {
                                let entries = entriesDocs.compactMap { JournalEntry(dictionary: $0.data()) }
                                allEntries.append(contentsOf: entries)
                                print("   [\(journalDoc.documentID)] \(entries.count)件のエントリを取得")
                            }
                            group.leave()
                        }
                }
                
                group.notify(queue: .main) {
                    // 日付でソートして制限
                    let sortedEntries = allEntries.sorted { $0.date > $1.date }.prefix(limit)
                    print("✅ 代替方法で合計\(sortedEntries.count)件のエントリを取得しました")
                    completion(.success(Array(sortedEntries)))
                }
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
    
    // 全快完了を保存
    func saveFullChargeEntry(_ entry: FullChargeEntry, completion: @escaping (Result<Void, Error>) -> Void) {
        let userId = "default_user"
        
        print("💚 全快完了をFirebaseに保存開始...")
        print("   日付キー: \(entry.dateKey)")
        print("   エントリID: \(entry.id)")
        print("   ソース: \(entry.source)")
        
        // 日毎のドキュメント構造: users/{userId}/journals/{dateKey}/fullCharges/{entryId}
        let docRef = db.collection("users")
            .document(userId)
            .collection("journals")
            .document(entry.dateKey)
            .collection("fullCharges")
            .document(entry.id)
        
        docRef.setData(entry.toDictionary()) { error in
            if let error = error {
                print("❌ Firebase保存エラー: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("✅ 全快完了をFirebaseに保存成功!")
                print("   パス: users/\(userId)/journals/\(entry.dateKey)/fullCharges/\(entry.id)")
                completion(.success(()))
            }
        }
    }
    
    // 特定の日の全快完了を取得
    func getFullChargesForDate(_ date: Date, completion: @escaping (Result<[FullChargeEntry], Error>) -> Void) {
        let userId = "default_user"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let dateKey = formatter.string(from: date)
        
        print("📖 \(dateKey)の全快完了を取得中...")
        
        db.collection("users")
            .document(userId)
            .collection("journals")
            .document(dateKey)
            .collection("fullCharges")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 取得エラー: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📭 全快完了が見つかりませんでした")
                    completion(.success([]))
                    return
                }
                
                let entries = documents.compactMap { doc -> FullChargeEntry? in
                    return FullChargeEntry(dictionary: doc.data())
                }
                
                print("✅ \(entries.count)件の全快完了を取得しました")
                completion(.success(entries))
            }
    }
    
    // すべての全快完了を取得（最新順）
    func getAllFullCharges(limit: Int = 50, completion: @escaping (Result<[FullChargeEntry], Error>) -> Void) {
        let userId = "default_user"
        print("📖 すべての全快完了を取得中（最大\(limit)件）...")
        
        // collectionGroupクエリを試す
        db.collectionGroup("fullCharges")
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ collectionGroupクエリエラー: \(error.localizedDescription)")
                    
                    // collectionGroupが失敗した場合、代替方法を試す
                    if error.localizedDescription.contains("index") || error.localizedDescription.contains("requires an index") {
                        print("⚠️ Firestoreインデックスが必要です")
                        print("   代替方法で全快完了を取得します...")
                        self.getAllFullChargesAlternative(userId: userId, limit: limit, completion: completion)
                    } else {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("📭 全快完了が見つかりませんでした（snapshotがnil）")
                    completion(.success([]))
                    return
                }
                
                print("📦 Firestoreから\(documents.count)件の全快完了ドキュメントを取得")
                
                let entries = documents.compactMap { doc -> FullChargeEntry? in
                    return FullChargeEntry(dictionary: doc.data())
                }
                
                print("✅ \(entries.count)件の全快完了をパースしました")
                completion(.success(entries))
            }
    }
    
    // 代替方法：日付ドキュメントを列挙して全快完了を取得
    private func getAllFullChargesAlternative(userId: String, limit: Int, completion: @escaping (Result<[FullChargeEntry], Error>) -> Void) {
        print("🔄 代替方法で全快完了を取得中...")
        
        db.collection("users")
            .document(userId)
            .collection("journals")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ journals取得エラー: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let journalDocs = snapshot?.documents else {
                    print("📭 journalsドキュメントが見つかりませんでした")
                    completion(.success([]))
                    return
                }
                
                print("📅 \(journalDocs.count)個の日付ドキュメントを発見")
                
                var allEntries: [FullChargeEntry] = []
                let group = DispatchGroup()
                
                for journalDoc in journalDocs {
                    group.enter()
                    self.db.collection("users")
                        .document(userId)
                        .collection("journals")
                        .document(journalDoc.documentID)
                        .collection("fullCharges")
                        .getDocuments { chargesSnapshot, chargesError in
                            if let chargesError = chargesError {
                                print("❌ fullCharges取得エラー [\(journalDoc.documentID)]: \(chargesError.localizedDescription)")
                            } else if let chargesDocs = chargesSnapshot?.documents {
                                let entries = chargesDocs.compactMap { FullChargeEntry(dictionary: $0.data()) }
                                allEntries.append(contentsOf: entries)
                                if !entries.isEmpty {
                                    print("   [\(journalDoc.documentID)] \(entries.count)件の全快完了を取得")
                                }
                            }
                            group.leave()
                        }
                }
                
                group.notify(queue: .main) {
                    let sortedEntries = allEntries.sorted { $0.date > $1.date }.prefix(limit)
                    print("✅ 代替方法で合計\(sortedEntries.count)件の全快完了を取得しました")
                    completion(.success(Array(sortedEntries)))
                }
            }
    }
}

