import SwiftUI

struct WaterIntakeView: View {
    let userAnswers: [String: Any]
    @State private var cupsConsumed: Int = 0
    @State private var dailyGoal: Int = 8
    
    @State private var morningReminder = false
    @State private var lunchReminder = false
    @State private var afternoonReminder = false
    @State private var eveningReminder = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.accentPrimary)
                        
                        Text("Water Intake")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Stay hydrated to boost energy and maintain wellness")
                            .font(.subheadline)
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Progress Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today's Progress")
                                    .font(.caption)
                                    .foregroundColor(Color.textSecondary)
                                Text("\(cupsConsumed)/\(dailyGoal) cups")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.accentPrimary)
                            }
                            
                            Spacer()
                            
                            CircularProgressView(progress: Double(cupsConsumed) / Double(dailyGoal))
                        }
                        
                        ProgressView(value: Double(cupsConsumed), total: Double(dailyGoal))
                            .tint(Color.accentPrimary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.accentPrimary.opacity(0.1))
                    )
                    
                    // Water Cups Grid
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Track Your Water")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(1...dailyGoal, id: \.self) { cup in
                                WaterCupButton(number: cup, isFilled: cup <= cupsConsumed) {
                                    if cup <= cupsConsumed {
                                        cupsConsumed = cup - 1
                                    } else {
                                        cupsConsumed = cup
                                    }
                                }
                            }
                        }
                    }
                    
                    // Quick Actions
                    VStack(spacing: 12) {
                        Button {
                            if cupsConsumed < dailyGoal {
                                cupsConsumed += 1
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add 1 Cup")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.accentPrimary)
                            )
                            .foregroundColor(Color.backgroundPrimary)
                        }
                        
                        Button {
                            cupsConsumed = 0
                        } label: {
                            Text("Reset Today")
                                .font(.subheadline)
                                .foregroundColor(Color.textSecondary)
                        }
                    }
                    
                    // Reminders Section - Now managed centrally
                    Text("Hydration reminders can be configured in the main Notification Settings.")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.surfacePrimary))
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .onAppear {
                NotificationManager.shared.requestPermission()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.accentPrimary)
                    }
                }
            }
        }
    }
}

struct WaterCupButton: View {
    let number: Int
    let isFilled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: isFilled ? "drop.fill" : "drop")
                    .font(.system(size: 32))
                    .foregroundColor(isFilled ? Color.accentPrimary : Color.textSecondary)
                
                Text("\(number)")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFilled ? Color.accentPrimary.opacity(0.1) : Color.surfacePrimary)
            )
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.textSecondary.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(width: 60, height: 60)
    }
}

#Preview {
    WaterIntakeView(userAnswers: [:])
}
