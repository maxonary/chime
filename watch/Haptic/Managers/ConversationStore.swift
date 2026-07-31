import Foundation

class ConversationStore: ObservableObject {
  @Published var conversations: [Conversation] = []
  @Published var currentConversation: Conversation?

  private let storePath: URL
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()

  init() {
    let fm = FileManager.default
    let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    self.storePath = appSupport.appendingPathComponent("conversations")

    do {
      try fm.createDirectory(at: storePath, withIntermediateDirectories: true)
    } catch {
      print("[ConversationStore] Failed to create directory: \(error)")
    }

    loadConversations()
    loadLastActiveConversation()
  }

  func createConversation(title: String = "New Chat") -> Conversation {
    let conv = Conversation(title: title)
    conversations.append(conv)
    currentConversation = conv
    save(conv)
    return conv
  }

  func saveMessage(_ message: Message, to conversationId: String) {
    if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
      conversations[index].messages.append(message)
      conversations[index].updatedAt = Date()
      save(conversations[index])
      currentConversation = conversations[index]
    }
  }

  func updateConversationTitle(_ id: String, newTitle: String) {
    if let index = conversations.firstIndex(where: { $0.id == id }) {
      conversations[index].title = newTitle
      save(conversations[index])
    }
  }

  private func save(_ conversation: Conversation) {
    let path = storePath.appendingPathComponent("\(conversation.id).json")
    do {
      let data = try encoder.encode(conversation)
      try data.write(to: path)
    } catch {
      print("[ConversationStore] Failed to save: \(error)")
    }
  }

  private func loadConversations() {
    let fm = FileManager.default
    do {
      let files = try fm.contentsOfDirectory(at: storePath, includingPropertiesForKeys: nil)
      conversations = files
        .filter { $0.pathExtension == "json" }
        .compactMap { path in
          guard let data = try? Data(contentsOf: path) else { return nil }
          return try? decoder.decode(Conversation.self, from: data)
        }
        .sorted { $0.updatedAt > $1.updatedAt }
    } catch {
      print("[ConversationStore] Failed to load: \(error)")
    }
  }

  private func loadLastActiveConversation() {
    let settings = AppSettings.load()
    if let lastId = settings.lastActiveConversationId,
       let conv = conversations.first(where: { $0.id == lastId }) {
      currentConversation = conv
    } else if !conversations.isEmpty {
      currentConversation = conversations[0]
    }
  }

  func setActiveConversation(_ conversation: Conversation) {
    currentConversation = conversation
    var settings = AppSettings.load()
    settings.lastActiveConversationId = conversation.id
    settings.save()
  }
}
