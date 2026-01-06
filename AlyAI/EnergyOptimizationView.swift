import SwiftUI

struct EnergyOptimizationView: View {
    let userAnswers: [String: Any]
    var title: String = "Energy Optimization"
    @State private var energyLevel: Double = 5
    @State private var completedTasks: Set<UUID> = []
    @State private var energyBoosts: [EnergyBoost] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.orange)
                        
                        Text(title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Boost and sustain your energy throughout the day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Current Energy Level
                    energyLevelCard
                    
                    // Energy Boosters
                    energyBoostersSection
                    
                    // Daily Energy Tips
                    energyTipsSection
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
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
        .onAppear {
            loadEnergyBoosts()
        }
    }
    
    private var energyLevelCard: some View {
        VStack(spacing: 16) {
            Text("Current Energy Level")
                .font(.headline)
            
            HStack(spacing: 20) {
                ForEach(1...10, id: \.self) { level in
                    Button {
                        energyLevel = Double(level)
                    } label: {
                        Circle()
                            .fill(level <= Int(energyLevel) ? Color.orange : Color.gray.opacity(0.3))
                            .frame(width: level <= Int(energyLevel) ? 20 : 16, height: level <= Int(energyLevel) ? 20 : 16)
                    }
                }
            }
            
            Text(energyDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private var energyBoostersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Energy Boosters")
                .font(.headline)
            
            ForEach(energyBoosts) { boost in
                EnergyBoostRow(
                    boost: boost,
                    isCompleted: completedTasks.contains(boost.id)
                ) {
                    if completedTasks.contains(boost.id) {
                        completedTasks.remove(boost.id)
                    } else {
                        completedTasks.insert(boost.id)
                    }
                }
            }
        }
    }
    
    private var energyTipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sustain Your Energy")
                .font(.headline)
            
            EnergyTipCard(icon: "sun.max.fill", title: "Morning Sunlight", description: "Get 15-20 minutes of natural light within 2 hours of waking", color: .yellow)
            EnergyTipCard(icon: "fork.knife", title: "Balanced Meals", description: "Eat protein and complex carbs every 3-4 hours", color: .green)
            EnergyTipCard(icon: "drop.fill", title: "Stay Hydrated", description: "Drink water consistently throughout the day", color: .blue)
            EnergyTipCard(icon: "figure.walk", title: "Movement Breaks", description: "Stand and move for 5 minutes every hour", color: .orange)
        }
    }
    
    private var energyDescription: String {
        switch Int(energyLevel) {
        case 1...3: return "Low energy - time for a boost!"
        case 4...6: return "Moderate energy - maintain it!"
        case 7...10: return "High energy - feeling great!"
        default: return "Track your energy"
        }
    }
    
    private func loadEnergyBoosts() {
        energyBoosts = [
            EnergyBoost(title: "10-minute walk", icon: "figure.walk", duration: "10 min", benefit: "+2 energy"),
            EnergyBoost(title: "Healthy snack", icon: "leaf.fill", duration: "5 min", benefit: "+1 energy"),
            EnergyBoost(title: "Power nap", icon: "moon.zzz.fill", duration: "20 min", benefit: "+3 energy"),
            EnergyBoost(title: "Deep breathing", icon: "wind", duration: "5 min", benefit: "+1 energy"),
            EnergyBoost(title: "Cold water splash", icon: "drop.fill", duration: "2 min", benefit: "+1 energy"),
            EnergyBoost(title: "Stretch break", icon: "figure.flexibility", duration: "5 min", benefit: "+1 energy")
        ]
    }
}

struct EnergyBoost: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let duration: String
    let benefit: String
}

struct EnergyBoostRow: View {
    let boost: EnergyBoost
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isCompleted ? .orange : .gray)
                
                Image(systemName: boost.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(boost.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    HStack {
                        Text(boost.duration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(boost.benefit)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCompleted ? Color.orange.opacity(0.1) : Color(.systemGray6))
            )
        }
    }
}

struct EnergyTipCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    EnergyOptimizationView(userAnswers: [:])
}
