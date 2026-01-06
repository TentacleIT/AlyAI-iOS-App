import SwiftUI

struct CycleTrackingView: View {
    @ObservedObject var manager = CycleManager.shared
    @State private var isEditing = false
    @State private var selectedDate = Date()
    @State private var cycleLength = 28.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Text("Cycle Tracking")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                if manager.metadata.lastPeriodDate != nil {
                    Button(action: { isEditing.toggle() }) {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(Color.success)
                    }
                }
            }
            
            if manager.metadata.lastPeriodDate == nil {
                setupView
            } else {
                cycleStatusView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surfacePrimary)
                .shadow(color: Color.shadow, radius: 8, x: 0, y: 4)
        )
        .sheet(isPresented: $isEditing) {
            setupSheet
        }
    }
    
    // MARK: - Views
    
    private var setupView: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 32))
                .foregroundColor(Color.error) // Red/Pink for cycle
            
            Text("Let's get to know your cycle")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.textPrimary)
            
            Text("Tracking helps us tailor your daily wellness.")
                .font(.caption)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                isEditing = true
            } label: {
                Text("Log Last Period")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.backgroundPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.error))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    private var cycleStatusView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Circular Day Indicator
                ZStack {
                    Circle()
                        .stroke(Color.error.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(manager.currentDayInCycle) / CGFloat(manager.metadata.cycleLength))
                        .stroke(Color.error, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 80, height: 80)
                    
                    VStack(spacing: 0) {
                        Text("Day")
                            .font(.caption2)
                            .foregroundColor(Color.textSecondary)
                        Text("\(manager.currentDayInCycle)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color.textPrimary)
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(manager.currentPhase.rawValue)
                        .font(.headline)
                        .foregroundColor(Color.error)
                    
                    Text(manager.currentPhase.description)
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                    
                    if let next = manager.estimatedNextPeriod {
                        Text("Next: \(next.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
            
            Divider().background(Color.textSecondary.opacity(0.2))
            
            // Quick Phase Actions/Tips
            HStack {
                phaseTip(icon: "bed.double.fill", text: phaseSleepTip)
                Spacer()
                phaseTip(icon: "fork.knife", text: phaseNutritionTip)
            }
        }
    }
    
    private var setupSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Cycle Details")) {
                    DatePicker("Last Period Start", selection: $selectedDate, displayedComponents: .date)
                    
                    VStack(alignment: .leading) {
                        Text("Cycle Length: \(Int(cycleLength)) days")
                        Slider(value: $cycleLength, in: 21...40, step: 1)
                    }
                }
            }
            .navigationTitle("Cycle Setup")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isEditing = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        manager.updateMetadata(lastPeriod: selectedDate, length: Int(cycleLength))
                        isEditing = false
                    }
                }
            }
            .onAppear {
                if let start = manager.metadata.lastPeriodDate {
                    selectedDate = start
                }
                cycleLength = Double(manager.metadata.cycleLength)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func phaseTip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color.textSecondary)
            Text(text)
                .font(.caption)
                .foregroundColor(Color.textSecondary)
        }
    }
    
    private var phaseSleepTip: String {
        switch manager.currentPhase {
        case .menstrual: return "Rest more"
        case .follicular: return "Normal sleep"
        case .ovulation: return "Active days"
        case .luteal: return "Prioritize sleep"
        case .unknown: return "Track sleep"
        }
    }
    
    private var phaseNutritionTip: String {
        switch manager.currentPhase {
        case .menstrual: return "Iron-rich foods"
        case .follicular: return "Light & fresh"
        case .ovulation: return "Balanced meals"
        case .luteal: return "Complex carbs"
        case .unknown: return "Healthy diet"
        }
    }
}
