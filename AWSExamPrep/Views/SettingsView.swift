import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var context

    @State private var showClearAlert = false

    @Query private var allQuestions: [Question]

    var body: some View {
        NavigationStack {
            Form {
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
                  footer: {
                    Text("Add .md question files to the question_bank folder in Xcode, then rebuild to import new questions. Clearing the bank resets imported file tracking.")
                }

                // About
                Section {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Format", value: "Markdown (.md)")
                } header: { Text("About") }
                  footer: {
                    Text("AWS Exam Prep · Practice questions loaded from local markdown files.")
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
                Text("This permanently removes every question from your bank and resets import tracking. Rebuild the app to reimport from .md files.")
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    private func clearBank() {
        for q in allQuestions {
            try? QuestionBankService.shared.delete(q, from: context)
        }
        // Reset imported file tracking so files are re-imported on next launch
        UserDefaults.standard.removeObject(forKey: "imported_question_bank_files")
    }
}
