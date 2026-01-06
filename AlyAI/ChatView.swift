import SwiftUI

struct ChatView: View {
    @EnvironmentObject var userSession: UserSession
    let userAnswers: [String: Any]
    @ObservedObject var chatStore: ChatStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputText = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(chatStore.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .tint(.alyPrimary)
                                    Text("AlyAI is thinking...")
                                        .font(.caption)
                                        .foregroundColor(.alyTextSecondary)
                                    Spacer()
                                }
                                .padding()
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
                
                // Input
                HStack(spacing: 12) {
                    TextField("Message AlyAI...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.alyCard)
                        )
                        .foregroundColor(.alyTextPrimary)
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(inputText.isEmpty ? AnyShapeStyle(Color.gray) : AnyShapeStyle(Color.alyPrimary))
                    }
                    .disabled(inputText.isEmpty || isLoading)
                }
                .padding()
                .background(Color.alyBackground)
            }
            .background(Color.alyBackground)
            .navigationTitle("Chat with AlyAI")
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
            let currentFocus = userAnswers["current_focus"] as? String ?? "wellness"
            let name = userSession.userName
            let greeting = name.isEmpty ? "Hi!" : "Hi \(name)!"
            
            let welcome = "\(greeting) I'm AlyAI, your compassionate companion. I'm here to support you with \(currentFocus.lowercased()). What's on your mind today?"
            
            chatStore.addMessage(welcome, isUser: false)
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        let userMessage = inputText
        chatStore.addMessage(userMessage, isUser: true)
        inputText = ""
        isLoading = true
        
        let conversationHistory = chatStore.messages.map { msg in
            "\(msg.isUser ? "User" : "AlyAI"): \(msg.content)"
        }.joined(separator: "\n")
        
        let currentFocus = userAnswers["current_focus"] as? String ?? "general wellness"
        let energyLevel = userAnswers["energy_level"] as? String ?? "moderate energy"
        let activityHistory = ActivityManager.shared.getHistoryForOpenAI()
        
        let name = userSession.userName
        
        // Gender-aware Context: Inject Cycle Data if Female
        var cycleContext = ""
        if let gender = userAnswers["gender"] as? String, gender.caseInsensitiveCompare("female") == .orderedSame {
            cycleContext = "\n" + CycleManager.shared.getCycleContextForAI()
        }
        
        let prompt = """
        The user’s name is \(name).
        Address the user by name naturally and warmly.
        Do not use generic greetings such as ‘Hello Friend’ or ‘Hi there’ when a name is available.
        
        You are AlyAI, a compassionate AI life companion providing emotional, mental, and physical support.
        
        USER CONTEXT:
        - Name: \(name)
        - Current Priority: \(currentFocus)
        - Energy Levels: \(energyLevel)\(cycleContext)
        
        RECENT ACTIVITY & INSIGHTS:
        \(activityHistory)
        
        CONVERSATION HISTORY:
        \(conversationHistory)
        
        Respond with empathy, validation, and practical guidance. 
        Refer to the user's recent insights or completed actions if relevant to show continuity and awareness (e.g. "I see you meditated yesterday...").
        Keep responses conversational (2-4 sentences). Be warm and supportive.
        """
        
        OpenAIService.shared.runAssessment(prompt: prompt) { response in
            DispatchQueue.main.async {
                chatStore.addMessage(response, isUser: false)
                isLoading = false
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.content)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(message.isUser ? AnyShapeStyle(Color.alyPrimary) : AnyShapeStyle(Color.alyCard))
                )
                .foregroundColor(message.isUser ? .white : .alyTextPrimary)
            
            if !message.isUser { Spacer() }
        }
    }
}

#Preview {
    ChatView(userAnswers: ["current_focus": "Managing stress or anxiety"], chatStore: ChatStore())
}
