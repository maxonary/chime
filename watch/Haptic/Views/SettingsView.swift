import SwiftUI

struct SettingsView: View {
  @EnvironmentObject var sessionManager: AgentSessionManager
  @Environment(\.dismiss) var dismiss
  @State private var settings = AppSettings.load()

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        HStack {
          Text("Settings")
            .font(.title3.bold())
          Spacer()
          Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
          }
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Gateway URL")
            .font(.caption.bold())
          TextField("URL", text: .init(
            get: { settings.gatewayURL.absoluteString },
            set: { settings.gatewayURL = URL(string: $0) ?? settings.gatewayURL }
          ))
          .font(.caption2)
          .textFieldStyle(.roundedBorder)
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Auth Token")
            .font(.caption.bold())
          SecureField("Token", text: $settings.userToken)
            .font(.caption2)
            .textFieldStyle(.roundedBorder)
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Model")
            .font(.caption.bold())
          Picker("Model", selection: $settings.agentModel) {
            Text("Claude Opus 5").tag("claude-opus-5")
            Text("Claude Sonnet 5").tag("claude-sonnet-5")
          }
          .font(.caption2)
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Web Research")
            .font(.caption.bold())
          Toggle("Auto-research", isOn: $settings.autoResearch)
            .font(.caption)
        }

        Button(action: { saveAndDismiss() }) {
          Text("Save & Close")
            .font(.caption.bold())
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(6)
        }

        Spacer()
      }
      .padding(12)
    }
  }

  private func saveAndDismiss() {
    settings.save()
    dismiss()
  }
}

#Preview {
  SettingsView()
    .environmentObject(AgentSessionManager())
}
