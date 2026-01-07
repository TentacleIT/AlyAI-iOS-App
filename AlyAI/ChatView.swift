import SwiftUI

struct ChatView_Enhanced: View {
    @EnvironmentObject var userSession: UserSession
    @ObservedObject var personalizationContext = PersonalizationContext.shared
    let userAnswers: [String: Any]
    @ObservedObject var chatStore: ChatStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with personalized greeting
                VStack(alignment: .leading, spacing: 8) {
                    Text("AlyAI")
                        .font(.headline)
                        .foregroundColor(.alyaiPrimary)
                    
                    Text(personalizationContext.getPersonalizedGreeting())
                        .font(.caption)
                        .foregroundColor(.alyTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.alyBackground)
                .borderBottom(color: Color.alyCard, width: 1)
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(chatStore.messages) { message in
                                MessageBubble_Enhanced(message: message, userName: personalizationContext.userName)
                                    .id(message.id)
                            }
                            
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .tint(.alyaiPrimary)
                                    Text("AlyAI is thinking...")
                                        .font(.caption)
                                        .foregroundColor(.alyTextSecondary)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.alyCard)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .background(Color.alyBackground)
                    .onChange(of: chatStore.messages.count) { oldValue, newValue in
                        if let lastMessage = chatStore.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Section
                VStack(spacing: 12) {
                    if !errorMessage?.isEmpty ?? false {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage ?? "An error occurred")
                                .font(.caption)
                                .foregroundColor(.red)
                            Spacer()
                            Button(action: { errorMessage = nil }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    HStack(spacing: 12) {
                        TextField("Share your thoughts...", text: $inputText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.alyCard)
                            .cornerRadius(20)
                            .lineLimit(1...5)
                            .foregroundColor(.alyTextPrimary)
                        
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(
                                    inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading
                                    ? AnyShapeStyle(Color.gray.opacity(0.5))
                                    : AnyShapeStyle(Color.alyaiPrimary)
                                )
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    }
                    .padding()
                    .background(Color.alyBackground)
                }
            }
            .background(Color.alyBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.alyTextPrimary)
                    }
                }
            }
        }
        .onAppear {
            sendWelcomeMessage()
        }
    }
    
    private func sendWelcomeMessage() {
        if chatStore.messages.isEmpty {
            let welcome = personalizationContext.getPersonalizedGreeting() + " What would you like to talk about today?"
            chatStore.addMessage(welcome, isUser: false)
        }
    }
    
    private func sendMessage() {
        let trimmedInput = inputText.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedInput.isEmpty else { return }
        guard trimmedInput.count <= 4000 else {
            errorMessage = "Message is too long (maximum 4000 characters)"
            return
        }
        
        let userMessage = trimmedInput
        chatStore.addMessage(userMessage, isUser: true)
        inputText = ""
        isLoading = true
        errorMessage = nil
        
        let conversationHistory = chatStore.messages.map { msg in
            "\(msg.isUser ? "User" : "AlyAI"): \(msg.content)"
        }.joined(separator: "\n")
        
        // Build comprehensive personalized prompt
        let personalizedContext = personalizationContext.buildAIContextString()
        
        let prompt = """
        \(personalizedContext)
        
        CONVERSATION HISTORY:
        \(conversationHistory)
        
        CURRENT USER MESSAGE: \(userMessage)
        
        RESPONSE GUIDELINES:
        1. Respond with deep empathy and understanding
        2. Reference their specific situation, goals, and needs
        3. Make the response feel personal and tailored to them
        4. Use their name naturally if appropriate
        5. Consider their energy level and stress level when suggesting actions
        6. Keep responses conversational (2-4 sentences typically)
        7. Be warm, supportive, and non-judgmental
        8. Avoid generic advice - everything must be specific to their context
        """
        
        OpenAIService.shared.runAssessment(prompt: prompt) { [weak self] response in
            DispatchQueue.main.async {
                self?.chatStore.addMessage(response, isUser: false)
                self?.isLoading = false
            }
        }
    }
}

// MARK: - Enhanced Message Bubble
struct MessageBubble_Enhanced: View {
    let message: ChatMessage
    let userName: String
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if !message.isUser {
                    Text("AlyAI")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.alyaiPrimary)
                        .padding(.leading, 12)
                }
                
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.isUser ? .white : .alyTextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isUser
                        ? Color.alyaiPrimary
                        : Color.alyCard
                    )
                    .cornerRadius(16)
                
                Text(message.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.alyTextSecondary)
                    .padding(.horizontal, 12)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Helper Extension
extension View {
    func borderBottom(color: Color, width: CGFloat) -> some View {
        VStack(spacing: 0) {
            self
            Divider()
                .background(color)
                .frame(height: width)
        }
    }
}

#Preview {
    ChatView_Enhanced(
        userAnswers: [:],
        chatStore: ChatStore()
    )
    .environmentObject(UserSession())
}
