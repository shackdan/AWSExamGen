//
//  SettingsView.swift
//  AWSExamPrep
//
//  Copyright (c) 2026 Dan Newton
//  Licensed under CC BY-NC 4.0
//  https://creativecommons.org/licenses/by-nc/4.0/
//
//  You may share and adapt this code for non-commercial purposes only.
//  Attribution is required.
//
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    private var allQuestions: [Question] { QuestionBankService.shared.allQuestions }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Label("Questions in bank", systemImage: "doc.text.fill")
                        Spacer()
                        Text("\(allQuestions.count)")
                            .foregroundStyle(.secondary)
                    }
                } header: { Text("Question Bank") }
                  footer: {
                    Text("Add .json files to the question_bank folder in Xcode and rebuild to load new questions.")
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Format", value: "JSON (.json)")
                } header: { Text("About") }
                  footer: {
                    Text("AWS Exam Prep · Practice questions loaded from bundled JSON files.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
