import SwiftUI

struct VoiceControlView: View {
  @EnvironmentObject var sessionManager: AgentSessionManager
  @State private var textInput = ""
  @State private var isSendingEnabled = false

  var body: some View {
    VStack(spacing: 12) {
      if !sessionManager.isListening {
        HStack(spacing: 8) {
          TextField("Message...", text: $textInput)
            .font(.caption)
            .onChange(of: textInput) { _, newValue in
              isSendingEnabled = !newValue.trimmingCharacters(in: .whitespaces).isEmpty
            }

          Button(action: send) {
            Image(systemName: "paperplane.fill")
              .font(.caption)
          }
          .disabled(!isSendingEnabled)
          .foregroundColor(isSendingEnabled ? .blue : .gray)
        }
      } else {
        HStack(spacing: 8) {
          Circle()
            .fill(Color.red)
            .frame(width: 8, height: 8)

          Text("Listening...")
            .font(.caption)

          Spacer()

          Button(action: { sessionManager.stopListening() }) {
            Image(systemName: "stop.fill")
              .font(.caption)
          }
        }
        .padding(8)
        .background(Color.gray.opacity(0.3))
        .cornerRadius(8)
      }

      Button(action: toggleListening) {
        Image(systemName: sessionManager.isListening ? "mic.fill" : "mic")
          .font(.system(size: 20))
          .frame(maxWidth: .infinity)
          .frame(height: 44)
          .background(sessionManager.isListening ? Color.red : Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
      }

      if let error = sessionManager.error {
        Text(error)
          .font(.caption2)
          .foregroundColor(.red)
          .lineLimit(2)
      }
    }
    .padding(12)
    .background(Color.gray.opacity(0.2))
  }

  private func send() {
    sessionManager.sendMessage(textInput)
    textInput = ""
  }

  private func toggleListening() {
    if sessionManager.isListening {
      sessionManager.stopListening()
    } else {
      sessionManager.startListening()
    }
  }
}

#Preview {
  VoiceControlView()
    .environmentObject(AgentSessionManager())
}
