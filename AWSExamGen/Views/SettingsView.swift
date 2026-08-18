//
//  SettingsView.swift
//  AWSExamGen
//
//  Copyright (c) 2026 Dan Newton
//  Licensed under CC BY-NC 4.0
//  https://creativecommons.org/licenses/by-nc/4.0/
//
//  You may share and adapt this code for non-commercial purposes only.
//  Attribution is required.
//
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isImporterPresented = false
    @State private var importAlert: ImportAlert?

    private var allQuestions: [Question] { QuestionBankService.shared.allQuestions }
    private var importedFilenames: [String] { QuestionBankService.shared.importedFilenames }

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

                    Button {
                        isImporterPresented = true
                    } label: {
                        Label("Import JSON File…", systemImage: "square.and.arrow.down")
                    }

                    if !importedFilenames.isEmpty {
                        ForEach(importedFilenames, id: \.self) { filename in
                            Text(filename)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .onDelete(perform: deleteImportedFiles)
                    }
                } header: { Text("Question Bank") }
                  footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Import .json question bank files, or add them to the question_bank folder in Xcode and rebuild.")
                        Link("Generate additional questions with aws-exam-gen", destination: URL(string: "https://github.com/shackdan/aws-exam-gen")!)
                    }
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Format", value: "JSON (.json)")
                    Link("Made in the newtonlab", destination: URL(string: "https://blog.thenewtonlab.com")!)
                } header: { Text("About") }
                  footer: {
                    Text("AWS Exam Gen · Practice questions loaded from bundled and imported JSON files.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $isImporterPresented,
                // Files Safari downloads as JSON are often mistagged with a generic
                // type instead of public.json, which would hide them under a strict
                // .json-only filter. Actual content is still validated on import.
                allowedContentTypes: [.json, .plainText, .data],
                allowsMultipleSelection: true
            ) { result in
                handleImport(result)
            }
            .alert(item: $importAlert) { alert in
                Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importAlert = ImportAlert(title: "Import Failed", message: error.localizedDescription)

        case .success(let urls):
            var addedCount = 0
            var failures: [String] = []
            for url in urls {
                do {
                    addedCount += try QuestionBankService.shared.importFile(from: url)
                } catch {
                    failures.append("\(url.lastPathComponent): \(error.localizedDescription)")
                }
            }
            if !failures.isEmpty {
                importAlert = ImportAlert(title: "Some Files Failed", message: failures.joined(separator: "\n"))
            } else {
                importAlert = ImportAlert(title: "Import Complete", message: "Added \(addedCount) question(s).")
            }
        }
    }

    private func deleteImportedFiles(at offsets: IndexSet) {
        for index in offsets {
            QuestionBankService.shared.removeImportedFile(importedFilenames[index])
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

private struct ImportAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
