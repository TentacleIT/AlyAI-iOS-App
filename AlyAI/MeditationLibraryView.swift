import SwiftUI
import AVKit

struct MeditationLibraryView: View {
    @ObservedObject var meditationManager = MeditationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVideo: MeditationVideo?
    @State private var showVideoPlayer = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Daily Meditation Hero Card
                    if let daily = meditationManager.dailyMeditation {
                        DailyMeditationHeroCard(daily: daily) {
                            selectedVideo = daily.video
                            showVideoPlayer = true
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    
                    // Categories Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Categories")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(meditationManager.meditationLibrary) { libraryCategory in
                                    CategoryCard(libraryCategory: libraryCategory) {
                                        // Navigate to category detail
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Progress Section
                    ProgressCard(progress: meditationManager.progress)
                        .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .background(Color(red: 0.95, green: 0.93, blue: 0.98)) // Light purple background
            .navigationTitle("Meditation Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .sheet(isPresented: $showVideoPlayer) {
            if let video = selectedVideo {
                MeditationVideoPlayerView(video: video) {
                    Task {
                        await meditationManager.recordSession(video: video)
                    }
                }
            }
        }
        .onAppear {
            meditationManager.loadProgress()
            meditationManager.loadDailyMeditation()
        }
    }
}

// MARK: - Daily Meditation Hero Card

struct DailyMeditationHeroCard: View {
    let daily: DailyMeditation
    let onPlay: () -> Void
    
    var body: some View {
        ZStack {
            // Background Image (placeholder with gradient)
            LinearGradient(
                colors: [
                    Color(red: 0.8, green: 0.9, blue: 1.0),
                    Color(red: 1.0, green: 0.95, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                // Subtle pattern overlay
                Image(systemName: "sparkles")
                    .font(.system(size: 100))
                    .foregroundColor(.white.opacity(0.1))
                    .offset(x: 50, y: -30)
            )
            
            // Content
            VStack(spacing: 12) {
                Spacer()
                
                // Play Button
                Button(action: onPlay) {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .offset(x: 3)
                        )
                        .shadow(color: .purple.opacity(0.4), radius: 20, x: 0, y: 10)
                }
                
                // Title
                Text(daily.video.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                // Description
                Text(daily.personalizedMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .frame(height: 280)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let libraryCategory: MeditationLibraryCategory
    let onTap: () -> Void
    
    private var categoryColor: Color {
        switch libraryCategory.category.color {
        case "cyan": return .cyan
        case "indigo": return .indigo
        case "purple": return .purple
        case "blue": return .blue
        case "pink": return .pink
        case "orange": return .orange
        default: return .purple
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                Image(systemName: libraryCategory.category.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(categoryColor.opacity(0.3))
                    )
                
                Spacer()
                
                // Category Name
                Text(libraryCategory.category.rawValue)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                // Session Count
                Text("\(libraryCategory.sessionCount) sessions")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                // Description
                Text(libraryCategory.category.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                
                // Arrow
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .frame(width: 220, height: 260)
            .background(
                LinearGradient(
                    colors: [categoryColor, categoryColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: categoryColor.opacity(0.3), radius: 15, x: 0, y: 8)
        }
    }
}

// MARK: - Progress Card

struct ProgressCard: View {
    let progress: MeditationProgress
    
    private var progressPercentage: Double {
        let target = 30.0 // 30-day goal
        return min(Double(progress.currentStreak) / target, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Progress")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(progress.currentStreak) of 30 days streak")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                }
            }
            .frame(height: 8)
            
            // Message
            Text(progress.getStreakStatus())
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Video Player View

struct MeditationVideoPlayerView: View {
    let video: MeditationVideo
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var hasCompleted = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Video Player Placeholder
                ZStack {
                    LinearGradient(
                        colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(spacing: 16) {
                        Image(systemName: video.category.icon)
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("Video Player")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("Meditation video would play here")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        // Simulate play button
                        Button {
                            hasCompleted = true
                            onComplete()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mark as Complete")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.purple)
                            .cornerRadius(25)
                        }
                    }
                }
                .frame(height: 300)
                .cornerRadius(20)
                .padding()
                
                // Video Info
                VStack(alignment: .leading, spacing: 12) {
                    Text(video.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Label("\(video.duration) min", systemImage: "clock")
                        Spacer()
                        Label(video.category.rawValue, systemImage: video.category.icon)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    Text(video.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Meditation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if !hasCompleted {
                            onComplete()
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MeditationLibraryView()
}
