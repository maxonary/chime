import SwiftUI

struct ContentView: View {
  @EnvironmentObject var sessionManager: AgentSessionManager
  @State private var isLoading = true
  @State private var scale: CGFloat = 1.0
  @State private var rotation: Double = 0
  @State private var offsetY: CGFloat = 0

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: 0) {
        Spacer()

        Button(action: toggleListening) {
          Text("🧿")
            .font(.system(size: 120))
            .scaleEffect(scale)
            .rotationEffect(.degrees(isLoading ? rotation : 0))
            .offset(y: isLoading ? 0 : offsetY)
        }
        .disabled(isLoading)

        Spacer()
      }
    }
    .onAppear {
      setupGateway()
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

    withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
      rotation = 360
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
      isLoading = false
      startIdleAnimation()
    }
  }

  private func startIdleAnimation() {
    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
      offsetY = 8
    }
    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
      scale = 1.08
    }
  }

  private func startPulseAnimation() {
    withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
      scale = 1.4
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(AgentSessionManager())
}
