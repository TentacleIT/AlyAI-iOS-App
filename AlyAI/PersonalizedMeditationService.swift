import Foundation

// MARK: - Personalized Meditation Content Service

class PersonalizedMeditationService {
    static let shared = PersonalizedMeditationService()
    
    private init() {}
    
    // MARK: - YouTube Integration
    
    /// Search YouTube for meditation videos based on user's specific needs
    func searchYouTubeMeditation(for userNeeds: [String], currentFocus: String) async -> [MeditationVideo] {
        var videos: [MeditationVideo] = []
        
        // Generate search queries based on user's needs
        let searchQueries = generateSearchQueries(from: userNeeds, focus: currentFocus)
        
        for query in searchQueries.prefix(3) { // Limit to 3 queries
            if let searchResults = await searchYouTube(query: query) {
                videos.append(contentsOf: searchResults)
            }
        }
        
        return videos
    }
    
    private func generateSearchQueries(from needs: [String], focus: String) -> [String] {
        var queries: [String] = []
        
        // Map user needs to meditation search terms
        let needsMapping: [String: String] = [
            "overthinking": "stop overthinking meditation guided",
            "be heard": "finding your voice meditation confidence",
            "anxiety": "anxiety relief meditation guided",
            "stress": "stress relief meditation guided",
            "sleep": "deep sleep meditation guided",
            "focus": "focus and concentration meditation",
            "confidence": "self confidence meditation guided",
            "relationships": "healthy relationships meditation",
            "self-love": "self love meditation guided",
            "motivation": "motivation and energy meditation",
            "calm": "inner peace and calm meditation",
            "healing": "emotional healing meditation guided"
        ]
        
        // Generate queries from user's greatest needs
        for need in needs {
            let needLower = need.lowercased()
            for (key, searchTerm) in needsMapping {
                if needLower.contains(key) {
                    queries.append(searchTerm)
                    break
                }
            }
        }
        
        // Add query from current focus
        if !focus.isEmpty {
            let focusLower = focus.lowercased()
            for (key, searchTerm) in needsMapping {
                if focusLower.contains(key) {
                    queries.append(searchTerm)
                    break
                }
            }
        }
        
        // Fallback: general meditation
        if queries.isEmpty {
            queries.append("guided meditation for beginners")
        }
        
        print("🔍 Generated search queries: \(queries)")
        return queries
    }
    
    private func searchYouTube(query: String) async -> [MeditationVideo]? {
        // YouTube Data API v3 endpoint
        // Get API key from environment variable or Info.plist
        guard let apiKey = getYouTubeAPIKey(), !apiKey.isEmpty else {
            print("❌ YouTube API key not configured")
            return nil
        }
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(encodedQuery)&type=video&videoDuration=medium&maxResults=5&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid YouTube API URL")
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ YouTube API request failed")
                return nil
            }
            
            let result = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
            return result.items.map { item in
                MeditationVideo(
                    title: item.snippet.title,
                    duration: 10, // Default duration, can be fetched from video details
                    description: item.snippet.description,
                    category: .anxietyRelief, // Determined by search query
                    videoURL: "https://www.youtube.com/watch?v=\(item.id.videoId)",
                    thumbnailURL: item.snippet.thumbnails.medium.url,
                    tags: [query]
                )
            }
        } catch {
            print("❌ YouTube search error: \(error)")
            return nil
        }
    }
    
    // MARK: - OpenAI Integration
    
    /// Generate personalized meditation script using OpenAI
    func generatePersonalizedMeditationScript(for userNeeds: [String], userName: String, currentFocus: String) async -> String? {
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        
        guard !apiKey.isEmpty else {
            print("❌ OpenAI API key not found")
            return nil
        }
        
        // Create personalized prompt
        let prompt = createMeditationPrompt(needs: userNeeds, userName: userName, focus: currentFocus)
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4.1-mini",
            "messages": [
                ["role": "system", "content": "You are a compassionate meditation guide who creates personalized, calming meditation scripts."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ OpenAI API request failed")
                return nil
            }
            
            let result = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            let script = result.choices.first?.message.content ?? ""
            
            print("✅ Generated personalized meditation script (\(script.count) characters)")
            return script
            
        } catch {
            print("❌ OpenAI generation error: \(error)")
            return nil
        }
    }
    
    private func createMeditationPrompt(needs: [String], userName: String, focus: String) -> String {
        let needsText = needs.joined(separator: ", ")
        
        return """
        Create a personalized 10-minute guided meditation script for \(userName).
        
        Their greatest needs are: \(needsText)
        Current focus: \(focus)
        
        The meditation should:
        1. Address their specific needs and challenges
        2. Use their name (\(userName)) naturally throughout
        3. Be calming, compassionate, and empowering
        4. Include breathing exercises
        5. Provide practical affirmations related to their needs
        6. Be approximately 10 minutes when read aloud (1500-2000 words)
        
        Format: Write as a spoken meditation guide script with clear pauses marked as [pause].
        Tone: Warm, supportive, and encouraging.
        """
    }
    
    /// Generate audio from meditation script using OpenAI TTS
    func generateMeditationAudio(from script: String) async -> URL? {
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        
        guard !apiKey.isEmpty else {
            print("❌ OpenAI API key not found")
            return nil
        }
        
        let url = URL(string: "https://api.openai.com/v1/audio/speech")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "tts-1",
            "input": script,
            "voice": "nova", // Calm, soothing voice
            "speed": 0.9 // Slightly slower for meditation
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ OpenAI TTS request failed")
                return nil
            }
            
            // Save audio to temporary file
            let tempDir = FileManager.default.temporaryDirectory
            let audioURL = tempDir.appendingPathComponent("meditation_\(UUID().uuidString).mp3")
            
            try data.write(to: audioURL)
            print("✅ Generated meditation audio: \(audioURL)")
            
            return audioURL
            
        } catch {
            print("❌ OpenAI TTS error: \(error)")
            return nil
        }
    }
    
    // MARK: - Intelligent Video Selection
    
    /// Select best meditation video based on user's profile
    func selectPersonalizedVideo(for context: PersonalizationContext) async -> MeditationVideo? {
        print("🎯 Selecting personalized meditation for user: \(context.userName)")
        print("📋 Greatest needs: \(context.greatestNeeds)")
        print("🎯 Current focus: \(context.currentFocus)")
        
        // DISABLED: YouTube URLs don't work with AVPlayer
        // AVPlayer requires direct video file URLs (.mp4, .m3u8, etc.)
        // YouTube watch URLs are web pages, not video files
        
        // Try YouTube search first (DISABLED - returns incompatible URLs)
        // let youtubeVideos = await searchYouTubeMeditation(
        //     for: context.greatestNeeds,
        //     currentFocus: context.currentFocus
        // )
        // 
        // if let video = youtubeVideos.first {
        //     print("✅ Selected YouTube video: \(video.title)")
        //     return video
        // }
        
        print("ℹ️ YouTube search disabled (incompatible with AVPlayer)")
        print("ℹ️ Using meditation library videos instead")
        
        // Return nil to fallback to category-based library selection
        print("ℹ️ Returning nil to use category-based library videos")
        
        // DISABLED: OpenAI generation (can be re-enabled for audio-only meditations)
        // if let script = await generatePersonalizedMeditationScript(
        //     for: context.greatestNeeds,
        //     userName: context.userName,
        //     currentFocus: context.currentFocus
        // ) {
        //     // For now, return a video with the script in description
        //     // In production, you'd generate audio and pair with visuals
        //     return MeditationVideo(
        //         title: "Personalized Meditation for \(context.userName)",
        //         duration: 10,
        //         description: script,
        //         category: .anxietyRelief,
        //         videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        //         tags: context.greatestNeeds
        //     )
        // }
        
        return nil
    }
    
    // MARK: - Configuration
    
    /// Get YouTube API key from environment variable or Info.plist
    private func getYouTubeAPIKey() -> String? {
        // Option 1: Environment variable (for development/testing)
        if let envKey = ProcessInfo.processInfo.environment["YOUTUBE_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // Option 2: Info.plist (for production)
        if let infoPlistKey = Bundle.main.object(forInfoDictionaryKey: "YOUTUBE_API_KEY") as? String, !infoPlistKey.isEmpty {
            return infoPlistKey
        }
        
        return nil
    }
}

// MARK: - YouTube API Models

struct YouTubeSearchResponse: Codable {
    let items: [YouTubeSearchItem]
}

struct YouTubeSearchItem: Codable {
    let id: YouTubeVideoId
    let snippet: YouTubeSnippet
}

struct YouTubeVideoId: Codable {
    let videoId: String
}

struct YouTubeSnippet: Codable {
    let title: String
    let description: String
    let thumbnails: YouTubeThumbnails
}

struct YouTubeThumbnails: Codable {
    let medium: YouTubeThumbnail
}

struct YouTubeThumbnail: Codable {
    let url: String
}

// MARK: - OpenAI API Models

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

struct OpenAIMessage: Codable {
    let content: String
}
