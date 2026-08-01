import Foundation

struct AppSettings: Codable {
  var gatewayURL: URL
  var userToken: String
  var agentModel: String
  var autoResearch: Bool
  var lastActiveConversationId: String?

  init(
    gatewayURL: URL = URL(string: "http://localhost:8788")!,
    userToken: String = "",
    agentModel: String = "claude-opus-5",
    autoResearch: Bool = true,
    lastActiveConversationId: String? = nil
  ) {
    self.gatewayURL = gatewayURL
    self.userToken = userToken
    self.agentModel = agentModel
    self.autoResearch = autoResearch
    self.lastActiveConversationId = lastActiveConversationId
  }

  static func load() -> AppSettings {
    let defaults = UserDefaults.standard
    if let data = defaults.data(forKey: "appSettings"),
       let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
      return settings
    }
    return AppSettings()
  }

  func save() {
    let defaults = UserDefaults.standard
    if let data = try? JSONEncoder().encode(self) {
      defaults.set(data, forKey: "appSettings")
    }
  }
}
