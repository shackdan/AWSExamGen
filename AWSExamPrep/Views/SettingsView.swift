import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var context

    @AppStorage("openai_api_key") private var apiKey = ""
    @State private var showKey        = false
    @State private var showClearAlert = false
    @State private var savedBanner    = false

    @Query private var allQuestions: [Question]

    private let llm = LLMService.shared

    var body: some View {
        NavigationStack {
            Form {
                // Model backend
                Section {
                    HStack {
                        Image(systemName: llm.loadedModelName != nil
                              ? "brain.head.profile" : "cloud.fill")
                            .foregroundStyle(llm.loadedModelName != nil ? .purple : .blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(llm.loadedModelName ?? "No local model found")
                                .font(.subheadline.bold())
                            Text(llm.backendDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: { Text("Inference Backend") }
                  footer: {
                    Text("On-device models run entirely on your iPhone with no data leaving the device. Priority: Apple Intelligence → Core ML bundle → OpenAI cloud.")
                }

                // OpenAI key (cloud fallback)
                Section {
                    HStack {
                        Group {
                            if showKey {
                                TextField("sk-…", text: $apiKey)
                            } else {
                                SecureField("sk-…", text: $apiKey)
                            }
                        }
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))

                        Button {
                            showKey.toggle()
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Button("Save Key") {
                        applyKey()
                        savedBanner = true
                    }
                    .disabled(apiKey.isEmpty)

                    if savedBanner {
                        Label("Saved — cloud generation enabled", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("OpenAI API Key")
                } footer: {
                    Text("Used only when no on-device model is available. Stored on-device; never shared. Get a key at platform.openai.com.")
                }

                // Question bank management
                Section {
                    HStack {
                        Label("Questions in bank", systemImage: "doc.text.fill")
                        Spacer()
                        Text("\(allQuestions.count)")
                            .foregroundStyle(.secondary)
                    }
                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        Label("Clear Question Bank", systemImage: "trash")
                    }
                    .disabled(allQuestions.isEmpty)
                } header: { Text("Question Bank") }

                // About
                Section {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Certification", value: "AWS SAA-C03 + more")
                } header: { Text("About") }
                  footer: {
                    Text("AWS Exam Prep · AI-generated practice questions and quizzes.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Clear all questions?", isPresented: $showClearAlert) {
                Button("Delete All", role: .destructive) { clearBank() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes every question from your bank. This cannot be undone.")
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    private func applyKey() {
        if llm.loadedModelName == nil {
            llm.backend = apiKey.isEmpty ? .local : .openAI(key: apiKey)
        }
    }

    private func clearBank() {
        for q in allQuestions {
            try? QuestionBankService.shared.delete(q, from: context)
        }
    }
}
