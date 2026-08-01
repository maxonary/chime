import SwiftUI

struct ContentView: View {
  @EnvironmentObject var sessionManager: AgentSessionManager
  @State private var showSettings = false

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: 0) {
        HStack {
          Text("Haptic")
            .font(.title3.bold())
          Spacer()
          Button(action: { showSettings = true }) {
            Image(systemName: "gear")
              .font(.system(size: 14))
          }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.2))

        Spacer()

        if let conversation = sessionManager.conversationStore.currentConversation {
          MessageListView(messages: conversation.messages)
        } else {
          Text("Start a conversation")
            .foregroundColor(.gray)
            .font(.caption)
        }

        Spacer()

        VoiceControlView()
          .environmentObject(sessionManager)
      }
      .ignoresSafeArea(edges: .bottom)
    }
    .sheet(isPresented: $showSettings) {
      SettingsView()
        .environmentObject(sessionManager)
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(AgentSessionManager())
}
