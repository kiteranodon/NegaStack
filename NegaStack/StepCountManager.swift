//
//  StepCountManager.swift
//  NegaStack
//
//  歩数データのみを管理するシンプルなマネージャー
//

import Foundation
import HealthKit
import Combine

class StepCountManager: ObservableObject {
    static let shared = StepCountManager()
    
    private let healthStore = HKHealthStore()
    
    @Published var todaySteps: Double = 0
    
    // HealthKitが利用可能かチェック
    var isHealthKitAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    // 歩数データタイプ
    private var stepCountType: HKQuantityType? {
        return HKQuantityType.quantityType(forIdentifier: .stepCount)
    }
    
    // MARK: - 権限リクエスト
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard isHealthKitAvailable else {
            print("❌ HealthKitが利用できません")
            completion(false, NSError(domain: "HealthKit", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available"]))
            return
        }
        
        guard let stepType = stepCountType else {
            completion(false, NSError(domain: "HealthKit", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Step count type not available"]))
            return
        }
        
        let typesToRead: Set<HKObjectType> = [stepType]
        
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
            if let error = error {
                print("❌ HealthKit権限エラー: \(error.localizedDescription)")
                completion(false, error)
            } else {
                print(success ? "✅ 歩数データの権限が許可されました" : "⚠️ 歩数データの権限が拒否されました")
                completion(success, nil)
            }
        }
    }
    
    // MARK: - 歩数データ取得
    
    /// 指定日の歩数を取得
    func fetchStepCount(for date: Date, completion: @escaping (Double?, Error?) -> Void) {
        guard let stepType = stepCountType else {
            completion(nil, NSError(domain: "HealthKit", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Step count type not available"]))
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            completion(nil, NSError(domain: "Date", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Invalid date"]))
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, 
                                     options: .cumulativeSum) { _, statistics, error in
            if let error = error {
                print("❌ 歩数データ取得エラー: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            let steps = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count())
            print("✅ \(self.formatDate(date))の歩数: \(steps?.formatted() ?? "0")歩")
            completion(steps, nil)
        }
        
        healthStore.execute(query)
    }
    
    /// 今日の歩数を取得（リアルタイム更新用）
    func fetchTodaySteps(completion: @escaping (Double?, Error?) -> Void) {
        fetchStepCount(for: Date()) { [weak self] steps, error in
            DispatchQueue.main.async {
                if let steps = steps {
                    self?.todaySteps = steps
                }
                completion(steps, error)
            }
        }
    }
    
    /// 複数日の歩数を一括取得
    func fetchStepCounts(from startDate: Date, to endDate: Date, completion: @escaping ([Date: Double]?, Error?) -> Void) {
        guard let stepType = stepCountType else {
            completion(nil, NSError(domain: "HealthKit", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Step count type not available"]))
            return
        }
        
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        guard let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) else {
            completion(nil, NSError(domain: "Date", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Invalid date range"]))
            return
        }
        
        var interval = DateComponents()
        interval.day = 1
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: start,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { _, collection, error in
            if let error = error {
                print("❌ 複数日の歩数取得エラー: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            
            var stepsByDate: [Date: Double] = [:]
            
            collection?.enumerateStatistics(from: start, to: end) { statistics, _ in
                if let steps = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) {
                    let date = statistics.startDate
                    stepsByDate[date] = steps
                    print("📊 \(self.formatDate(date)): \(steps.formatted())歩")
                }
            }
            
            print("✅ \(stepsByDate.count)日分の歩数データを取得しました")
            completion(stepsByDate, nil)
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - リアルタイム監視
    
    /// 歩数のリアルタイム監視を開始（アプリ起動中のみ）
    func startObservingSteps(completion: @escaping (Double) -> Void) {
        guard let stepType = stepCountType else { return }
        
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("❌ 歩数監視エラー: \(error.localizedDescription)")
                return
            }
            
            // 歩数が更新されたら再取得
            self?.fetchTodaySteps { steps, _ in
                if let steps = steps {
                    DispatchQueue.main.async {
                        completion(steps)
                    }
                }
            }
        }
        
        healthStore.execute(query)
        print("👀 歩数のリアルタイム監視を開始しました")
    }
    
    // MARK: - ヘルパーメソッド
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

