import SwiftUI

// MARK: - Enhanced Cycle Tracking Dashboard (Flo-Inspired)

struct CycleTrackingDashboard_Enhanced: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager = CycleManager.shared
    
    @State private var currentMonth: Date = Date()
    @State private var showSymptomSheet = false
    @State private var showPeriodLogger = false
    @State private var showQuickLog = false
    
    // Flo-inspired color palette
    private let primaryColor = Color(red: 1.0, green: 0.4, blue: 0.6) // Pink
    private let secondaryColor = Color(red: 0.9, green: 0.7, blue: 0.9) // Light purple
    private let accentColor = Color(red: 0.4, green: 0.7, blue: 0.9) // Blue for fertile days
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Enhanced Header with Cycle Day
                    enhancedHeaderSection
                    
                    // Quick Actions (Flo-inspired)
                    quickActionsSection
                    
                    // Cycle Overview Card
                    cycleOverviewCard
                    
                    // Calendar
                    CycleCalendarView(
                        monthLogs: manager.monthLogs,
                        metadata: manager.metadata,
                        themeColor: primaryColor,
                        currentMonth: currentMonth,
                        onPreviousMonth: { changeMonth(by: -1) },
                        onNextMonth: { changeMonth(by: 1) }
                    )
                    .padding(.horizontal)
                    
                    // Calendar Legend
                    enhancedCalendarLegend
                    
                    // Today's Log Section
                    todaysLogSection
                    
                    // Insights & Tips
                    if let insight = manager.todayInsight {
                        enhancedInsightsCard(insight: insight)
                    }
                    
                    // Educational Content
                    cyclePhaseEducation
                    
                    Spacer(minLength: 20)
                }
                .padding(.bottom)
            }
            .background(
                LinearGradient(
                    colors: [Color(uiColor: .systemBackground), secondaryColor.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Cycle Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showQuickLog = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(primaryColor)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showSymptomSheet) {
                ExpandedSymptomLogView()
            }
            .sheet(isPresented: $showPeriodLogger) {
                PeriodLoggerView()
            }
            .sheet(isPresented: $showQuickLog) {
                QuickLogView()
            }
        }
    }
    
    // MARK: - Enhanced Header Section
    
    private var enhancedHeaderSection: some View {
        VStack(spacing: 12) {
            // Cycle Day Badge
            HStack(spacing: 8) {
                Image(systemName: getCyclePhaseIcon())
                    .font(.system(size: 24))
                    .foregroundColor(primaryColor)
                
                Text("Day \(manager.currentDayInCycle) of \(manager.metadata.cycleLength)")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            // Phase Name
            Text(manager.currentPhase.rawValue)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(primaryColor)
            
            // Phase Description
            Text(manager.currentPhase.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Next Event
            if let nextEvent = getNextEvent() {
                HStack(spacing: 6) {
                    Image(systemName: nextEvent.icon)
                        .font(.caption)
                    Text(nextEvent.text)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(primaryColor.opacity(0.1))
                .cornerRadius(20)
                .foregroundColor(primaryColor)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(uiColor: .label).opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    // MARK: - Quick Actions Section (Flo-Inspired)
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickActionButton(
                        icon: "drop.fill",
                        title: "Log Period",
                        color: primaryColor,
                        action: { showPeriodLogger = true }
                    )
                    
                    QuickActionButton(
                        icon: "face.smiling",
                        title: "Log Mood",
                        color: Color.purple,
                        action: { showQuickLog = true }
                    )
                    
                    QuickActionButton(
                        icon: "heart.text.square",
                        title: "Symptoms",
                        color: Color.orange,
                        action: { showSymptomSheet = true }
                    )
                    
                    QuickActionButton(
                        icon: "bolt.fill",
                        title: "Energy",
                        color: Color.yellow,
                        action: { showQuickLog = true }
                    )
                    
                    QuickActionButton(
                        icon: "moon.zzz.fill",
                        title: "Sleep",
                        color: Color.indigo,
                        action: { showQuickLog = true }
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Cycle Overview Card
    
    private var cycleOverviewCard: some View {
        VStack(spacing: 16) {
            Text("Cycle Overview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                // Period Info
                OverviewItem(
                    icon: "drop.fill",
                    title: "Last Period",
                    value: formatDate(manager.metadata.lastPeriodDate),
                    color: primaryColor
                )
                
                Divider()
                
                // Cycle Length
                OverviewItem(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Cycle Length",
                    value: "\(manager.metadata.cycleLength) days",
                    color: Color.purple
                )
                
                Divider()
                
                // Ovulation
                OverviewItem(
                    icon: "sparkles",
                    title: "Ovulation",
                    value: formatDate(manager.metadata.ovulationEstimate),
                    color: accentColor
                )
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(uiColor: .label).opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    // MARK: - Enhanced Calendar Legend
    
    private var enhancedCalendarLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                LegendItem(color: primaryColor, label: "Period")
                LegendItem(color: accentColor, label: "Fertile")
                LegendItem(color: Color.green, label: "Ovulation")
                LegendItem(color: Color.orange, label: "PMS")
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground).opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Today's Log Section
    
    private var todaysLogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Log")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // Flow
                PeriodFlowTrackerView()
                    .padding()
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(16)
                
                // Mood & Energy
                MoodEnergyTrackerView()
                    .padding()
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(16)
                
                // Symptoms Summary
                SymptomSummaryView(showSheet: $showSymptomSheet)
                    .padding()
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(16)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Enhanced Insights Card
    
    private func enhancedInsightsCard(insight: CycleInsight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Today's Insight")
                    .font(.headline)
            }
            
            Text(insight.explanation)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !insight.whatToExpect.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("What to Expect")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(insight.whatToExpect)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !insight.copingTips.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tips for Today")
                        .font(.caption)
                        .fontWeight(.semibold)
                    ForEach(insight.copingTips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(primaryColor)
                            Text(tip)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    // MARK: - Cycle Phase Education
    
    private var cyclePhaseEducation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About \(manager.currentPhase.rawValue) Phase")
                .font(.headline)
            
            Text(getPhaseEducation())
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Nutrition Tips
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                    Text("Nutrition Tips")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                ForEach(getNutritionTips(), id: \.self) { tip in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                        Text(tip)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(20)
        .shadow(color: Color(uiColor: .label).opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    
    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func getCyclePhaseIcon() -> String {
        switch manager.currentPhase {
        case .menstrual: return "drop.fill"
        case .follicular: return "leaf.fill"
        case .ovulation: return "sparkles"
        case .luteal: return "moon.fill"
        case .unknown: return "questionmark.circle"
        }
    }
    
    private func getNextEvent() -> (icon: String, text: String)? {
        if let nextPeriod = manager.estimatedNextPeriod {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: nextPeriod).day ?? 0
            if days > 0 {
                return ("drop.fill", "Period in \(days) days")
            }
        }
        
        if let ovulation = manager.metadata.ovulationEstimate {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: ovulation).day ?? 0
            if days > 0 && days < 7 {
                return ("sparkles", "Ovulation in \(days) days")
            }
        }
        
        return nil
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func getPhaseEducation() -> String {
        switch manager.currentPhase {
        case .menstrual:
            return "Your body is shedding the uterine lining. Energy levels may be lower. Focus on rest, gentle movement, and self-care."
        case .follicular:
            return "Estrogen is rising, bringing increased energy and mood. Great time for new projects and social activities."
        case .ovulation:
            return "Peak fertility window. Energy and confidence are at their highest. Your body is releasing an egg."
        case .luteal:
            return "Progesterone is dominant. You may experience PMS symptoms. Focus on stress management and gentle exercise."
        case .unknown:
            return "Keep logging your cycle to get personalized insights and predictions."
        }
    }
    
    private func getNutritionTips() -> [String] {
        switch manager.currentPhase {
        case .menstrual:
            return [
                "Iron-rich foods (leafy greens, red meat)",
                "Warm, comforting meals",
                "Stay hydrated",
                "Vitamin C for iron absorption"
            ]
        case .follicular:
            return [
                "Lean proteins for energy",
                "Fresh fruits and vegetables",
                "Whole grains for sustained energy",
                "Fermented foods for gut health"
            ]
        case .ovulation:
            return [
                "Antioxidant-rich foods",
                "Healthy fats (avocado, nuts)",
                "Fiber-rich foods",
                "Stay well-hydrated"
            ]
        case .luteal:
            return [
                "Complex carbs to manage cravings",
                "Magnesium-rich foods (dark chocolate, nuts)",
                "Calcium for PMS symptoms",
                "Reduce salt and caffeine"
            ]
        case .unknown:
            return [
                "Balanced diet with variety",
                "Stay hydrated",
                "Listen to your body's needs"
            ]
        }
    }
}

// MARK: - Supporting Views

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .background(Color(uiColor: .systemBackground))
                    .frame(width: 60, height: 60)
                    .background(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct OverviewItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Quick Log View

struct QuickLogView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Quick Log Coming Soon")
                    .font(.title2)
                    .padding()
                
                Text("This will allow you to quickly log mood, energy, and symptoms.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Quick Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Period Logger View

struct PeriodLoggerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Period Logger Coming Soon")
                    .font(.title2)
                    .padding()
                
                Text("This will allow you to log your period start and end dates.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Log Period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CycleTrackingDashboard_Enhanced()
}
