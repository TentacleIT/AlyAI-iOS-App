import SwiftUI
import UIKit

struct FoodCalorieCalculatorView: View {
    @State private var showPicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var capturedImage: UIImage?
    @State private var resultText = "Take or upload a photo of your food"
    @State private var showSourceOptions = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .cornerRadius(12)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No image selected")
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                Text(resultText)
                    .multilineTextAlignment(.center)
                    .padding()
                    .font(.body)

                Spacer()

                Button {
                    showSourceOptions = true
                } label: {
                    HStack {
                        Image(systemName: "camera.circle.fill")
                        Text("Calculate Calories")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.alyaiPhysical)
                    )
                }
                .padding()
                .confirmationDialog(
                    "Select Image Source",
                    isPresented: $showSourceOptions,
                    titleVisibility: .visible
                ) {
                    Button("Take Photo") {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            pickerSource = .camera
                            showPicker = true
                        } else {
                            resultText = "Camera not available on simulator. Please run on a real device."
                        }
                    }

                    Button("Upload from Library") {
                        pickerSource = .photoLibrary
                        showPicker = true
                    }

                    Button("Cancel", role: .cancel) {}
                }
            }
            .padding()
            .navigationTitle("Food Calculator")
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
            .sheet(isPresented: $showPicker) {
                ImagePicker(sourceType: pickerSource, image: $capturedImage) { image in
                    analyzeFood(image: image)
                }
            }
        }
    }

    // MARK: - OpenAI Vision API
    func analyzeFood(image: UIImage) {
        resultText = "Analyzing food..."

        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            resultText = "Image processing failed"
            return
        }

        let base64Image = imageData.base64EncodedString()
        let apiKey = openAIKey()

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": """
                            Identify the food in this image and estimate calories.
                            Respond exactly in this format:
                            Food: <food name>
                            Calories: <number> kcal
                            """
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in

            if let error = error {
                DispatchQueue.main.async {
                    resultText = "Network error"
                }
                print("❌ Network error:", error)
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    resultText = "No response data"
                }
                return
            }

            if let raw = String(data: data, encoding: .utf8) {
                print("📦 OpenAI raw response:\n", raw)
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async {
                    resultText = "Invalid JSON response"
                }
                return
            }

            if let errorObj = json["error"] as? [String: Any],
               let message = errorObj["message"] as? String {
                DispatchQueue.main.async {
                    resultText = "API Error: \(message)"
                }
                print("❌ OpenAI error:", message)
                return
            }

            if
                let choices = json["choices"] as? [[String: Any]],
                let message = choices.first?["message"] as? [String: Any],
                let content = message["content"] as? String {

                DispatchQueue.main.async {
                    resultText = content
                }
            } else {
                DispatchQueue.main.async {
                    resultText = "Unexpected API response"
                }
                print("⚠️ Unexpected response format:", json)
            }

        }.resume()
    }

    // MARK: - API Key
    func openAIKey() -> String {
        // Safe key retrieval
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let key = dict["OPENAI_API_KEY"] as? String {
            return key
        }
        return ""
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var image: UIImage?
    var onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
    }
}
