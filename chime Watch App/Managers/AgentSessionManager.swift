import Foundation
import Combine
import Speech
import AVFoundation

@MainActor
class AgentSessionManager: ObservableObject {
  @Published var isConnected = false
  @Published var isListening = false
  @Published var currentResponse = ""
  @Published var error: String? = nil
  @Published var conversationStore: ConversationStore

  private let settings = AppSettings.load()
  private var sessionTask: URLSessionWebSocketTask?
  private var listeningTask: Task<Void, Never>?
  private var speechRecognizer: SFSpeechRecognizer?
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private let audioEngine = AVAudioEngine()
  private var speechBuffer = ""

  init() {
    self.conversationStore = ConversationStore()
    setupSpeech()
  }

  private func setupSpeech() {
    speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      self.error = "Audio setup failed"
    }

    SFSpeechRecognizer.requestAuthorization { status in
      if status != .authorized {
        DispatchQueue.main.async {
          self.error = "Speech recognition not authorized"
        }
      }
    }
  }

  func sendMessage(_ text: String) {
    guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
    guard let conversation = conversationStore.currentConversation else {
      _ = conversationStore.createConversation()
      sendMessage(text)
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
    } catch {
      self.error = "Error: \(error.localizedDescription)"
    }
  }

  func startListening() {
    guard speechRecognizer?.isAvailable == true else {
      self.error = "Speech recognition unavailable"
      return
    }

    do {
      try audioEngine.start()

      recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
      guard let recognitionRequest = recognitionRequest else { return }

      recognitionRequest.shouldReportPartialResults = true

      isListening = true
      speechBuffer = ""

      recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
        DispatchQueue.main.async {
          if let result = result {
            self.speechBuffer = result.bestTranscription.formattedString
            if result.isFinal {
              self.sendMessage(self.speechBuffer)
              self.stopListening()
            }
          }

          if let error = error as? NSError {
            if error.code != 216 {
              self.error = "Speech error: \(error.localizedDescription)"
            }
            self.stopListening()
          }
        }
      }

      let inputNode = audioEngine.inputNode
      let recordingFormat = inputNode.outputFormat(forBus: 0)
      inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
        self.recognitionRequest?.append(buffer)
      }

      audioEngine.prepare()
    } catch {
      self.error = "Failed to start recording"
      isListening = false
    }
  }

  func stopListening() {
    isListening = false
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionRequest?.endAudio()
    recognitionTask?.cancel()
    recognitionTask = nil
    recognitionRequest = nil
  }

  deinit {
    listeningTask?.cancel()
    sessionTask?.cancel(with: .goingAway, reason: nil)
  }
}
