import SwiftUI

struct InsightsView: View {
    let userAnswers: [String: Any]
    @ObservedObject private var activityManager = ActivityManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // Derived from answers or mock data
    private var wellnessScore: Int {
        let bodyConnection = Int(userAnswers["body_connection"] as? Double ?? 5)
        let energyLevel = userAnswers["energy_level"] as? String ?? ""
        var score = bodyConnection * 10
        
        if energyLevel.contains("energized") { score += 20 }
        else if energyLevel.contains("ups and downs") { score += 10 }
        
        return min(max(score, 40), 95) // Clamp between 40 and 95
    }
    
    private var userName: String {
        let raw = userAnswers["name"] as? String
        return raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.alyaiGradient)
                        
                        Text(userName.isEmpty ? "Your Insights" : "\(userName)'s Insights")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Patterns & reflections based on your journey")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Wellness Score Card
                    VStack(spacing: 16) {
                        Text("Wellness Score")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                                .frame(width: 150, height: 150)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(wellnessScore) / 100)
                                .stroke(
                                    Color.alyaiGradient,
                                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                                )
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(-90))
                            
                            VStack {
                                Text("\(wellnessScore)")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("/ 100")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("Based on your check-ins and activity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                    
                    // Focus Area Insight
                    if let needsRaw = userAnswers["greatest_need"] {
                        let focus: String = (needsRaw as? [String])?.joined(separator: ", ") ?? (needsRaw as? String) ?? "General Wellness"
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(.alyaiPrimary)
                                Text("Current Focus")
                                    .font(.headline)
                            }
                            
                            Text(focus)
                                .font(.title3)
                                .fontWeight(.bold)
                                .lineLimit(2)
                            
                            Text("You are taking active steps towards addressing these needs. Keep consistently engaging with your daily plan.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.alyaiLightPurple.opacity(0.2))
                        )
                        .padding(.horizontal)
                    }
                    
                    // Daily Insights Journal
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Insight Journal")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if activityManager.dailyInsights.isEmpty {
                            Text("Complete daily actions to unlock insights.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            ForEach(activityManager.dailyInsights.sorted(by: { $0.date > $1.date })) { insight in
                                InsightRowCard(insight: insight)
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.alyaiPrimary)
                    }
                }
            }
        }
    }
}

struct InsightRowCard: View {
    let insight: DailyInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 4) {
                Text(insight.date.formatted(.dateTime.day()))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.alyTextPrimary)
                Text(insight.date.formatted(.dateTime.month()))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.alyTextSecondary)
            }
            .frame(width: 50)
            .padding(.vertical, 8)
            .background(Color.alyCard)
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(insight.summary)
                    .font(.subheadline)
                    .foregroundColor(.alyTextPrimary)
                    .lineLimit(nil)
                
                if let mood = insight.emotionalSignal {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.alyDanger)
                        Text("Mood: \(mood)")
                            .font(.caption)
                            .foregroundColor(.alyTextSecondary)
                    }
                }
                
                if !insight.supportingActions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(insight.supportingActions, id: \.self) { action in
                                Text(action)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.alyPrimary.opacity(0.1)))
                                    .foregroundColor(.alyPrimary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

#Preview {
    InsightsView(userAnswers: [
        "current_focus": "Managing stress or anxiety",
        "energy_level": "I often feel tired",
        "body_connection": 7.0
    ])
}
