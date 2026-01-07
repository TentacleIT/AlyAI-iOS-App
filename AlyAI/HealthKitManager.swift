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
    @Published var errorMessage: String?
    
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
            errorMessage = "HealthKit is not available on this device."
            completion(false)
            return
        }
        
        // Safely create HealthKit types with proper error handling
        let typesToRead = createHealthKitTypesToRead()
        let typesToShare = createHealthKitTypesToShare()
        
        guard !typesToRead.isEmpty, !typesToShare.isEmpty else {
            print("❌ Failed to create HealthKit types")
            errorMessage = "Failed to initialize HealthKit types."
            completion(false)
            return
        }
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.fetchAllData()
                } else if let error = error {
                    print("HealthKit Authorization Error: \(error.localizedDescription)")
                    self?.errorMessage = "HealthKit authorization failed: \(error.localizedDescription)"
                }
                completion(success)
            }
        }
    }
    
    /// Safely create HealthKit types to read
    private func createHealthKitTypesToRead() -> Set<HKObjectType> {
        var types: [HKObjectType] = []
        
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.append(stepType)
        }
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            types.append(heartRateType)
        }
        if let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.append(hrvType)
        }
        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.append(sleepType)
        }
        if let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            types.append(restingHRType)
        }
        if let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) {
            types.append(mindfulType)
        }
        
        return Set(types)
    }
    
    /// Safely create HealthKit types to share
    private func createHealthKitTypesToShare() -> Set<HKObjectType> {
        var types: [HKObjectType] = []
        
        if let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) {
            types.append(mindfulType)
        }
        
        return Set(types)
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
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("❌ Unable to create step count type")
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            if let error = error {
                print("❌ Error fetching steps: \(error)")
                return
            }
            
            guard let result = result, let sum = result.sumQuantity() else { return }
            DispatchQueue.main.async {
                self?.stepCount = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchHeartRate() {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            print("❌ Unable to create heart rate type")
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            if let error = error {
                print("❌ Error fetching heart rate: \(error)")
                return
            }
            
            guard let sample = samples?.first as? HKQuantitySample else { return }
            DispatchQueue.main.async {
                self?.latestHeartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchSleep() {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("❌ Unable to create sleep analysis type")
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: [])
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, error in
            if let error = error {
                print("❌ Error fetching sleep: \(error)")
                return
            }
            
            guard let samples = samples as? [HKCategorySample] else { return }
            
            // Calculate total sleep duration
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
                self?.sleepHours = totalSeconds / 3600.0
            }
        }
        healthStore.execute(query)
    }
    
    private func fetchHRV() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            print("❌ Unable to create HRV type")
            return
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            if let error = error {
                print("❌ Error fetching HRV: \(error)")
                return
            }
            
            guard let sample = samples?.first as? HKQuantitySample else { return }
            DispatchQueue.main.async {
                self?.hrv = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            }
        }
        healthStore.execute(query)
    }
}
