import SwiftUI

@main
struct HapticApp: App {
  @StateObject private var sessionManager = AgentSessionManager()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(sessionManager)
    }
  }
}
