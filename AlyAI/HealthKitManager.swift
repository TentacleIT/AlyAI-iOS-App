import Foundation
import HealthKit
import SwiftUI
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var stepCount: Int = 0
    @Published var latestHeartRate: Double = 0
    @Published var sleepHours: Double = 0
    @Published var hrv: Double = 0
    
    // Track last sync to avoid excessive polling
    private var lastSyncDate: Date?
    
    init() {
        // Check if previously authorized or attempt to load if allowed
        // HealthKit doesn't tell us if we are authorized directly without requesting.
        // But we can try to fetch if we think we are.
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device.")
            completion(false)
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
            HKCategoryType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        let typesToShare: Set<HKObjectType> = [
            HKCategoryType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare as! Set<HKSampleType>, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthorized = true
                    self.fetchAllData()
                } else if let error = error {
                    print("HealthKit Authorization Error: \(error.localizedDescription)")
                }
                completion(success)
            }
        }
    }
    
    func fetchAllData() {
        guard isAuthorized else { return }
        fetchSteps()
        fetchHeartRate()
        fetchSleep()
        fetchHRV()
        lastSyncDate = Date()
    }
    
    private func fetchSteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else { return }
            DispatchQueue.main.async {
                self.stepCount = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchHeartRate() {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            DispatchQueue.main.async {
                self.latestHeartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchSleep() {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: [])
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            guard let samples = samples as? [HKCategorySample] else { return }
            
            // Calculate total sleep duration (inHours, as an example)
            let totalSeconds = samples.reduce(0.0) { result, sample in
                // Only count asleep time
                if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue || 
                   sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    return result + sample.endDate.timeIntervalSince(sample.startDate)
                }
                return result
            }
            
            DispatchQueue.main.async {
                self.sleepHours = totalSeconds / 3600.0
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchHRV() {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            DispatchQueue.main.async {
                self.hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            }
        }
        healthStore.execute(query)
    }
}
