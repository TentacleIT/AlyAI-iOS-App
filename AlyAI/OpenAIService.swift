import Foundation

final class OpenAIService {

    static let shared = OpenAIService()

    private let apiKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
    }()
    
    private let defaultTimeoutInterval: TimeInterval = 60.0

    func runAssessment(prompt: String, jsonMode: Bool = false, completion: @escaping (String) -> Void) {
        print("🤖 [OpenAIService] sending request... Prompt length: \(prompt.count)")

        guard !apiKey.isEmpty else {
            print("❌ [OpenAIService] OpenAI API key not configured")
            completion("Error: OpenAI API key is not configured.")
            return
        }

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("❌ [OpenAIService] Invalid URL")
            completion("Error: Invalid API endpoint URL.")
            return
        }
        
        var body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": jsonMode ? "You are a helpful assistant designed to output JSON." : "You are a compassionate AI life companion."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        
        if jsonMode {
            body["response_format"] = ["type": "json_object"]
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = defaultTimeoutInterval
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ [OpenAIService] Failed to serialize request body: \(error)")
            completion("Error: Failed to prepare request.")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network errors
            if let error = error {
                print("❌ [OpenAIService] Network Error: \(error.localizedDescription)")
                completion("Error: Network request failed - \(error.localizedDescription)")
                return
            }

            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [OpenAIService] Invalid response type")
                completion("Error: Invalid server response.")
                return
            }

            // Check HTTP status code
            guard httpResponse.statusCode == 200 else {
                print("❌ [OpenAIService] HTTP Error: \(httpResponse.statusCode)")
                let errorMessage = self.parseErrorResponse(data: data) ?? "HTTP Error \(httpResponse.statusCode)"
                completion("Error: \(errorMessage)")
                return
            }

            guard let data = data else {
                print("❌ [OpenAIService] No data received")
                completion("Error: No response data received.")
                return
            }
            
            // Log raw response for debugging
            if FeatureFlags.enableVerboseLogging, let rawString = String(data: data, encoding: .utf8) {
                print("📩 [OpenAIService] Raw Response: \(rawString)")
            }

            // Parse JSON response
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("❌ [OpenAIService] Failed to parse JSON response")
                    completion("Error: Invalid response format.")
                    return
                }
                
                // Check for API errors in response
                if let errorObj = json["error"] as? [String: Any],
                   let message = errorObj["message"] as? String {
                    print("❌ [OpenAIService] API Error: \(message)")
                    completion("Error: \(message)")
                    return
                }

                guard
                    let choices = json["choices"] as? [[String: Any]],
                    let message = choices.first?["message"] as? [String: Any],
                    let content = message["content"] as? String
                else {
                    print("❌ [OpenAIService] Failed to parse response structure")
                    completion("Error: Invalid response structure.")
                    return
                }

                print("✅ [OpenAIService] Success! Content length: \(content.count)")
                completion(content)
            } catch {
                print("❌ [OpenAIService] JSON parsing error: \(error)")
                completion("Error: Failed to parse response - \(error.localizedDescription)")
            }
        }
        .resume()
    }

    func generateImage(prompt: String, completion: @escaping (String?) -> Void) {
        print("🎨 [OpenAIService] Generating image for prompt: \(prompt)")
        
        guard !apiKey.isEmpty else {
            print("❌ [OpenAIService] OpenAI API key not configured")
            completion(nil)
            return
        }
        
        guard let url = URL(string: "https://api.openai.com/v1/images/generations") else {
            completion(nil)
            return
        }
        
        let body: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120 // Longer timeout for image generation
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ [OpenAIService] Failed to serialize image request: \(error)")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [OpenAIService] Image Generation Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("❌ [OpenAIService] Image generation HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                completion(nil)
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataArray = json["data"] as? [[String: Any]],
                  let first = dataArray.first,
                  let urlString = first["url"] as? String else {
                print("❌ [OpenAIService] Failed to parse image response")
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    print("Raw response: \(str)")
                }
                completion(nil)
                return
            }
            
            completion(urlString)
        }.resume()
    }

    func generateAudio(text: String, voice: String = "shimmer", completion: @escaping (Data?) -> Void) {
        print("🗣️ [OpenAIService] Generating audio for text: \(text.prefix(30))... Voice: \(voice)")

        guard !apiKey.isEmpty else {
            print("❌ [OpenAIService] OpenAI API key not configured")
            completion(nil)
            return
        }

        guard let url = URL(string: "https://api.openai.com/v1/audio/speech") else {
            completion(nil)
            return
        }

        let body: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": voice,
            "response_format": "mp3"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ [OpenAIService] Failed to serialize audio request: \(error)")
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [OpenAIService] Audio Generation Error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("❌ [OpenAIService] Audio generation HTTP error: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    print("Raw response: \(str)")
                }
                completion(nil)
                return
            }

            guard let data = data else {
                print("❌ [OpenAIService] Audio Request Failed or No Data")
                completion(nil)
                return
            }

            print("✅ [OpenAIService] Audio received! Size: \(data.count) bytes")
            completion(data)
        }.resume()
    }
    
    // MARK: - Helper Methods
    
    /// Parse error message from OpenAI error response
    private func parseErrorResponse(data: Data?) -> String? {
        guard let data = data else { return nil }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorObj = json["error"] as? [String: Any],
               let message = errorObj["message"] as? String {
                return message
            }
        } catch {
            print("Failed to parse error response: \(error)")
        }
        
        return nil
    }
}
