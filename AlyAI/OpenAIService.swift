import Foundation

final class OpenAIService {

    static let shared = OpenAIService()

    private let apiKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
    }()

    func runAssessment(prompt: String, jsonMode: Bool = false, completion: @escaping (String) -> Void) {
        print("🤖 [OpenAIService] sending request... Prompt length: \(prompt.count)")

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("❌ [OpenAIService] Invalid URL")
            completion("Invalid URL")
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
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in

            if let error = error {
                print("❌ [OpenAIService] Network Error: \(error.localizedDescription)")
                completion("Error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("❌ [OpenAIService] No data received")
                completion("Failed to generate assessment.")
                return
            }
            
            // Log raw response for debugging
            if let rawString = String(data: data, encoding: .utf8) {
                print("📩 [OpenAIService] Raw Response: \(rawString)")
            }

            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let choices = json["choices"] as? [[String: Any]],
                let message = choices.first?["message"] as? [String: Any],
                let content = message["content"] as? String
            else {
                print("❌ [OpenAIService] Failed to parse response structure")
                completion("Failed to generate assessment.")
                return
            }

            print("✅ [OpenAIService] Success! Content length: \(content.count)")
            completion(content)
        }
        .resume()
    }

    func generateImage(prompt: String, completion: @escaping (String?) -> Void) {
        print("🎨 [OpenAIService] Generating image for prompt: \(prompt)")
        
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
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ [OpenAIService] Image Generation Error: \(error.localizedDescription)")
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
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [OpenAIService] Audio Generation Error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                print("❌ [OpenAIService] Audio Request Failed or No Data")
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    print("Raw response: \(str)")
                }
                completion(nil)
                return
            }

            print("✅ [OpenAIService] Audio received! Size: \(data.count) bytes")
            completion(data)
        }.resume()
    }
}
