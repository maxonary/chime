import Foundation
import AVFoundation

@MainActor
class AgentSessionManager: NSObject, ObservableObject {
  @Published var isConnected = false
  @Published var isListening = false
  @Published var currentResponse = ""
  @Published var error: String?
  @Published var conversationStore: ConversationStore

  private var audioEngine: AVAudioEngine?
  private let settings = AppSettings.load()
  private var sessionTask: URLSessionWebSocketTask?
  private var listeningTask: Task<Void, Never>?

  override init() {
    conversationStore = ConversationStore()
    super.init()
    setupAudio()
  }

  private func setupAudio() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playAndRecord, mode: .default, options: [.duckOthers, .defaultToSpeaker])
      try audioSession.setActive(true)
    } catch {
      self.error = "Audio setup failed: \(error.localizedDescription)"
    }
  }

  func sendMessage(_ text: String) {
    guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
    guard let conversation = conversationStore.currentConversation else {
      conversationStore.createConversation()
      return
    }

    let userMessage = Message(role: .user, content: text)
    conversationStore.saveMessage(userMessage, to: conversation.id)

    Task {
      await fetchAgentResponse(for: conversation)
    }
  }

  private func fetchAgentResponse(for conversation: Conversation) async {
    do {
      let messages = conversation.messages.map { msg in
        ["role": msg.role.rawValue, "content": msg.content] as [String: Any]
      }

      var request = URLRequest(url: settings.gatewayURL.appendingPathComponent("/v1/chat/completions"))
      request.httpMethod = "POST"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.setValue("Bearer \(settings.userToken)", forHTTPHeaderField: "Authorization")

      let body: [String: Any] = [
        "model": settings.agentModel,
        "messages": messages,
        "stream": true
      ]

      request.httpBody = try JSONSerialization.data(withJSONObject: body)

      let (data, response) = try await URLSession.shared.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        self.error = "Gateway error: invalid response"
        return
      }

      let text = String(data: data, encoding: .utf8) ?? ""
      let assistantMessage = Message(role: .assistant, content: text)
      conversationStore.saveMessage(assistantMessage, to: conversation.id)
      currentResponse = text

      WKInterfaceDevice.current().play(.notification)
    } catch {
      self.error = "Error: \(error.localizedDescription)"
    }
  }

  func startListening() {
    isListening = true
    listeningTask = Task {
      // TODO: Implement actual voice recording with speech-to-text
      // For now, this is a placeholder
    }
  }

  func stopListening() {
    isListening = false
    listeningTask?.cancel()
  }

  deinit {
    listeningTask?.cancel()
    sessionTask?.cancel(with: .goingAway, reason: nil)
  }
}
