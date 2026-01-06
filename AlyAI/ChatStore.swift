import Foundation
import Combine

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let date = Date()
}

class ChatStore: ObservableObject {
    @Published var messages: [ChatMessage] = []
    
    func addMessage(_ content: String, isUser: Bool) {
        let message = ChatMessage(content: content, isUser: isUser)
        messages.append(message)
    }
    
    func clearMessages() {
        messages.removeAll()
    }
}
