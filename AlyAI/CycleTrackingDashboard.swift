import SwiftUI

// MARK: - Dashboard View

struct CycleTrackingDashboard: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager = CycleManager.shared
    
    @State private var currentMonth: Date = Date()
    @State private var showSymptomSheet = false
    
    private let themeColor = Color.error

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    // Calendar
                    CycleCalendarView(
                        monthLogs: manager.monthLogs,
                        metadata: manager.metadata,
                        themeColor: themeColor,
                        currentMonth: currentMonth,
                        onPreviousMonth: { changeMonth(by: -1) },
                        onNextMonth: { changeMonth(by: 1) }
                    ).padding(.horizontal)
                    
                    // Calendar Legend
                    calendarLegend.padding(.horizontal)
                    
                    // Daily Logging Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Log").font(.headline).padding(.horizontal)
                        
                        // Flow
                        PeriodFlowTrackerView().padding(.horizontal)
                        
                        // Mood & Energy
                        MoodEnergyTrackerView().padding(.horizontal)
                        
                        // Symptoms
                        SymptomSummaryView(showSheet: $showSymptomSheet).padding(.horizontal)
                    }
                    
                    // Insights
                    if let insight = manager.todayInsight {
                        InsightsPanelView(insight: insight).padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.bottom)
            }
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Cycle Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeColor)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showSymptomSheet) {
                ExpandedSymptomLogView()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(manager.currentPhase.rawValue)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(themeColor)
            
            Text(manager.currentPhase.description)
                .font(.headline)
                .foregroundColor(Color.textSecondary)
            
            if let next = manager.estimatedNextPeriod {
                Text("Next period expected \(next.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
                    .padding(.top, 4)
            }
        }.padding(.top)
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private var calendarLegend: some View {
        HStack(spacing: 16) {
            legendItem(color: .error.opacity(0.8), label: "Period")
            legendItem(color: .success.opacity(0.8), label: "Fertile")
            legendItem(color: .accentPrimary.opacity(0.8), label: "Ovulation")
            legendItem(color: .accentPrimary.opacity(0.6), label: "Safe")
        }
        .frame(maxWidth: .infinity)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(Color.textSecondary)
        }
    }
}

// MARK: - Insights

struct InsightsPanelView: View {
    let insight: CycleInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles").foregroundColor(Color.accentPrimary)
                Text("Daily Insight").font(.headline)
                Spacer()
                Text("\(insight.confidenceScore)% Confidence").font(.caption).foregroundColor(Color.textSecondary)
            }
            
            Text(insight.explanation)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
            Text("What to Expect:")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color.textSecondary)
            
            Text(insight.whatToExpect)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)
            
            if !insight.copingTips.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(insight.copingTips, id: \.self) { tip in
                        HStack(alignment: .top) {
                            Image(systemName: "heart.fill").font(.caption2).foregroundColor(Color.error).padding(.top, 2)
                            Text(tip).font(.caption).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
                .background(Color.error.opacity(0.05))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.surfacePrimary)
        .cornerRadius(16)
        .shadow(color: Color.shadow, radius: 5, x: 0, y: 2)
    }
}

// MARK: - Flow Tracker

struct PeriodFlowTrackerView: View {
    @ObservedObject var manager = CycleManager.shared
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Flow Intensity").font(.caption).foregroundColor(Color.textSecondary)
            Picker("Flow", selection: Binding(
                get: { manager.todayLog?.flowLevel ?? .none },
                set: {
                    var log = manager.todayLog ?? CycleLog(date: Date(), phase: manager.currentPhase)
                    log.flowLevel = $0
                    manager.saveLog(log)
                }
            )) {
                ForEach(PeriodFlow.allCases, id: \.self) { flow in
                    Text(flow.rawValue.capitalized).tag(flow)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Mood & Energy

struct MoodEnergyTrackerView: View {
    @ObservedObject var manager = CycleManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Mood
            VStack(alignment: .leading) {
                Text("Mood").font(.caption).foregroundColor(Color.textSecondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(MoodState.allCases, id: \.self) { mood in
                            Button {
                                updateMood(mood)
                            } label: {
                                VStack {
                                    Text(emoji(for: mood))
                                        .font(.title2)
                                        .padding(10)
                                        .background(isSelected(mood) ? Color.accentPrimary.opacity(0.2) : Color.textSecondary.opacity(0.1))
                                        .clipShape(Circle())
                                    Text(mood.rawValue).font(.caption2).foregroundColor(Color.textPrimary)
                                }
                            }
                        }
                    }
                }
            }
            
            // Energy Slider
            VStack(alignment: .leading) {
                HStack {
                    Text("Energy").font(.caption).foregroundColor(Color.textSecondary)
                    Spacer()
                    Text("\(manager.todayLog?.energyLevel ?? 5)/10").font(.caption).fontWeight(.bold)
                }
                Slider(value: Binding(
                    get: { Double(manager.todayLog?.energyLevel ?? 5) },
                    set: {
                        var log = manager.todayLog ?? CycleLog(date: Date(), phase: manager.currentPhase)
                        log.energyLevel = Int($0)
                        manager.saveLog(log)
                    }
                ), in: 1...10, step: 1)
                .tint(Color.accentPrimary)
            }
        }
        .padding()
        .background(Color.surfacePrimary)
        .cornerRadius(12)
    }
    
    private func isSelected(_ mood: MoodState) -> Bool {
        return manager.todayLog?.mood.state == mood
    }
    
    private func updateMood(_ mood: MoodState) {
        var log = manager.todayLog ?? CycleLog(date: Date(), phase: manager.currentPhase)
        log.mood.state = mood
        manager.saveLog(log)
    }
    
    private func emoji(for mood: MoodState) -> String {
        switch mood {
        case .happy: return "😊"
        case .anxious: return "😰"
        case .irritable: return "😠"
        case .low: return "😔"
        case .calm: return "😌"
        case .energetic: return "⚡️"
        case .sensitive: return "🥺"
        }
    }
}

// MARK: - Symptoms Summary

struct SymptomSummaryView: View {
    @ObservedObject var manager = CycleManager.shared
    @Binding var showSheet: Bool
    
    var body: some View {
        Button {
            showSheet = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Symptoms").font(.headline).foregroundColor(Color.textPrimary)
                    if let log = manager.todayLog, hasSymptoms(log) {
                        Text(symptomSummary(log)).font(.caption).foregroundColor(Color.textSecondary)
                    } else {
                        Text("Tap to log symptoms").font(.caption).foregroundColor(Color.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(Color.textSecondary)
            }
            .padding()
            .background(Color.surfacePrimary)
            .cornerRadius(12)
        }
    }
    
    private func hasSymptoms(_ log: CycleLog) -> Bool {
        let s = log.symptoms
        return (s.cramps?.isPresent ?? false) ||
               (s.headache?.isPresent ?? false) ||
               (s.bloating?.isPresent ?? false) ||
               (s.nausea?.isPresent ?? false) ||
               (s.backPain?.isPresent ?? false)
        // Check others if needed
    }
    
    private func symptomSummary(_ log: CycleLog) -> String {
        var list: [String] = []
        let s = log.symptoms
        if s.cramps?.isPresent == true { list.append("Cramps") }
        if s.headache?.isPresent == true { list.append("Headache") }
        if s.bloating?.isPresent == true { list.append("Bloating") }
        if s.backPain?.isPresent == true { list.append("Back Pain") }
        
        if list.isEmpty { return "No symptoms logged" }
        return list.joined(separator: ", ")
    }
}

// MARK: - Calendar

struct CycleCalendarView: View {
    var monthLogs: [Date: CycleLog]
    var metadata: CycleMetadata
    var themeColor: Color
    var currentMonth: Date
    var onPreviousMonth: () -> Void
    var onNextMonth: () -> Void
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button(action: onPreviousMonth) { Image(systemName: "chevron.left").foregroundColor(themeColor) }
                Spacer()
                Text(monthYearString).font(.headline)
                Spacer()
                Button(action: onNextMonth) { Image(systemName: "chevron.right").foregroundColor(themeColor) }
            }.padding(.horizontal)
            
            // Grid
            LazyVGrid(columns: columns, spacing: 10) {
                let days = daysInMonth()
                ForEach(days.indices, id: \.self) { index in
                    let date = days[index]
                    if let date = date {
                        dayCell(for: date)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color.surfacePrimary)
        .cornerRadius(16)
    }
    
    private func dayCell(for date: Date) -> some View {
        let log = monthLogs[Calendar.current.startOfDay(for: date)]
        let isToday = Calendar.current.isDateInToday(date)
        
        // Calculate phase if not logged
        // This ensures calendar shows predicted states (Period, Ovulation, etc.)
        let calculatedPhase = CycleManager.shared.phase(for: date)
        let phase = log?.cyclePhase ?? calculatedPhase
        
        let isPeriod = (log?.flowLevel != .none && log?.flowLevel != nil) || phase == .menstrual
        
        return VStack {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isToday ? themeColor : Color.textPrimary)
            
            // Indicators
            if isPeriod {
                Circle().fill(Color.error.opacity(0.8)).frame(width: 6, height: 6)
            } else if phase == .ovulation {
                Circle().fill(Color.accentPrimary.opacity(0.8)).frame(width: 6, height: 6)
            } else if phase == .follicular {
                // Fertile / Productive
                Circle().fill(Color.success.opacity(0.8)).frame(width: 6, height: 6)
            } else if phase == .luteal {
                // Safe / Low-fertility
                Circle().fill(Color.accentPrimary.opacity(0.6)).frame(width: 6, height: 6)
            }
        }
        .frame(height: 40)
        .background(isToday ? themeColor.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
    
    private var monthYearString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: currentMonth)
    }
    
    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else { return [] }
        
        let weekday = calendar.component(.weekday, from: firstDay)
        let offset = weekday - 1
        
        var days: [Date?] = Array(repeating: nil, count: offset)
        for i in 0..<range.count {
            if let date = calendar.date(byAdding: .day, value: i, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }
}
