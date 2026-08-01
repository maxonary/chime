import Foundation
import Combine
import AVFoundation

@MainActor
class AgentSessionManager: ObservableObject {
  @Published var isConnected = false
  @Published var isListening = false
  @Published var currentResponse = ""
  @Published var error: String? = nil
  @Published var conversationStore: ConversationStore

  private let settings = AppSettings.load()
  private var webSocketTask: URLSessionWebSocketTask?
  private var audioEngine = AVAudioEngine()
  private var listeningTask: Task<Void, Never>?
  private let audioPlayer = AVAudioPlayerNode()

  init() {
    self.conversationStore = ConversationStore()
    setupAudio()
  }

  private func setupAudio() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playAndRecord, mode: .default, options: [.duckOthers, .defaultToSpeaker])
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

      let mainMixer = audioEngine.mainMixerNode
      audioEngine.attach(audioPlayer)
      audioEngine.connect(audioPlayer, to: mainMixer, format: nil)
    } catch {
      self.error = "Audio setup failed"
    }
  }

  func startListening() {
    guard !isListening else { return }
    isListening = true

    listeningTask = Task {
      await connectToRealtime()
    }
  }

  func stopListening() {
    isListening = false
    listeningTask?.cancel()
    closeWebSocket()
  }

  private func connectToRealtime() async {
    guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
      self.error = "OpenAI API key not configured"
      return
    }

    let model = "gpt-4o-realtime-preview-2024-12-17"
    let urlString = "wss://api.openai.com/v1/realtime?model=\(model)"
    guard let url = URL(string: urlString) else {
      self.error = "Invalid WebSocket URL"
      return
    }

    var request = URLRequest(url: url)
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("openai-beta", forHTTPHeaderField: "openai-beta")

    webSocketTask = URLSession.shared.webSocketTask(with: request)
    webSocketTask?.resume()

    await receiveMessages()
    await captureAndSendAudio()
  }

  private func receiveMessages() async {
    while isListening, let webSocketTask = webSocketTask {
      do {
        let message = try await webSocketTask.receive()
        switch message {
        case .data(let data):
          handleRealtimeData(data)
        case .string(let str):
          if let data = str.data(using: .utf8) {
            handleRealtimeData(data)
          }
        @unknown default:
          break
        }
      } catch {
        if isListening {
          self.error = "WebSocket error: \(error.localizedDescription)"
        }
        break
      }
    }
  }

  private func handleRealtimeData(_ data: Data) {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return
    }

    if let type = json["type"] as? String {
      switch type {
      case "session.created":
        self.isConnected = true

      case "response.audio.delta":
        if let audio = json["delta"] as? String {
          playAudioData(audio)
        }

      case "response.text.done":
        if let text = json["text"] as? String {
          DispatchQueue.main.async {
            self.currentResponse = text
            let assistantMessage = Message(role: .assistant, content: text)
            if let conv = self.conversationStore.currentConversation {
              self.conversationStore.saveMessage(assistantMessage, to: conv.id)
            }
          }
        }

      default:
        break
      }
    }
  }

  private func captureAndSendAudio() async {
    let inputNode = audioEngine.inputNode
    guard let format = inputNode.outputFormat(forBus: 0) else {
      self.error = "Cannot get audio format"
      return
    }

    do {
      try audioEngine.start()

      inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
        self?.sendAudioToRealtime(buffer)
      }

      audioEngine.prepare()
    } catch {
      self.error = "Failed to start audio capture"
      stopListening()
    }
  }

  private func sendAudioToRealtime(_ buffer: AVAudioPCMBuffer) {
    guard let webSocketTask = webSocketTask else { return }

    let audioData = buffer.audioBufferList.pointee.mBuffers
    let bytes = audioData.mData?.assumingMemoryBound(to: UInt8.self)
    let byteCount = Int(audioData.mDataByteSize)

    if let bytes = bytes {
      let data = Data(bytes: bytes, count: byteCount)
      let base64Audio = data.base64EncodedString()

      let payload: [String: Any] = [
        "type": "input_audio_buffer.append",
        "audio": base64Audio
      ]

      if let jsonData = try? JSONSerialization.data(withJSONObject: payload) {
        if let jsonString = String(data: jsonData, encoding: .utf8) {
          webSocketTask.send(.string(jsonString)) { _ in }
        }
      }
    }
  }

  private func playAudioData(_ base64String: String) {
    guard let audioData = Data(base64Encoded: base64String) else { return }

    do {
      let audioFile = try AVAudioFile(forReading: audioData as NSURL as URL)
      if !audioPlayer.engine!.isRunning {
        try audioPlayer.engine?.start()
      }

      audioPlayer.scheduleFile(audioFile, at: nil)
      if !audioPlayer.isPlaying {
        audioPlayer.play()
      }
    } catch {
      self.error = "Failed to play audio"
    }
  }

  private func closeWebSocket() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    webSocketTask?.cancel(with: .goingAway, reason: nil)
    webSocketTask = nil
    isConnected = false
  }

  deinit {
    listeningTask?.cancel()
    closeWebSocket()
  }
}
