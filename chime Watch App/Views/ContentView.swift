import SwiftUI

struct ContentView: View {
  @EnvironmentObject var sessionManager: AgentSessionManager
  @State private var scale: CGFloat = 1.0

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      Button(action: toggleListening) {
        Text("🧿")
          .font(.system(size: 120))
          .scaleEffect(scale)
      }
    }
    .onAppear {
      setupGateway()
      startIdleAnimation()
    }
    .onChange(of: sessionManager.isListening) { _, isListening in
      if isListening {
        startPulseAnimation()
      } else {
        startIdleAnimation()
      }
    }
  }

  private func toggleListening() {
    if sessionManager.isListening {
      sessionManager.stopListening()
    } else {
      sessionManager.startListening()
    }
  }

  private func setupGateway() {
    var settings = AppSettings.load()
    settings.gatewayURL = URL(string: "https://chime-e1ks.onrender.com")!
    settings.userToken = "watch-token"
    settings.save()
  }

  private func startIdleAnimation() {
    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
      scale = 1.06
    }
  }

  private func startPulseAnimation() {
    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
      scale = 1.25
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(AgentSessionManager())
}
