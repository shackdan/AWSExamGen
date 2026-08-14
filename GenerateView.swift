//
//  GenerateView.swift
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
import SwiftData

struct GenerateView: View {
    @Environment(\.modelContext) private var context
    @State private var vm = GenerateViewModel()

    var body: some View {
        NavigationStack {
            Form {
                // Model info
                Section {
                    HStack {
                        Image(systemName: vm.isLocalModel ? "brain.head.profile" : "cloud.fill")
                            .foregroundStyle(vm.isLocalModel ? .purple : .blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vm.modelName).font(.headline)
                            Text(vm.isLocalModel ? "Running on Neural Engine" : "Cloud API")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                } header: { Text("Inference Backend") }

                // Config
                Section {
                    Stepper("Questions: \(vm.config.numQuestions)",
                            value: $vm.config.numQuestions, in: 1...20)

                    Picker("Certification", selection: $vm.config.certType) {
                        ForEach(certTypes, id: \.self) { Text($0).tag($0) }
                    }

                    Picker("Topic", selection: $vm.config.topic) {
                        ForEach(topics, id: \.self) { Text($0).tag($0) }
                    }

                    Toggle("Save to Question Bank", isOn: $vm.config.saveToBank)
                        .tint(.orange)
                } header: { Text("Configuration") }

                // Generate button
                Section {
                    Button {
                        Task { await vm.generate(context: context) }
                    } label: {
                        HStack {
                            Spacer()
                            if vm.isGenerating {
                                ProgressView().tint(.white)
                                Text("Generating…").bold()
                            } else {
                                Image(systemName: "sparkles")
                                Text("Generate Questions").bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(vm.isGenerating)
                    .listRowBackground(Color.orange)
                    .foregroundStyle(.white)
                }

                // Error
                if let err = vm.errorMessage {
                    Section {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                // Results preview
                if !vm.generatedQuestions.isEmpty {
                    Section {
                        ForEach(vm.generatedQuestions) { q in
                            QuestionRowView(question: q)
                        }
                    } header: {
                        Text("Generated — \(vm.generatedQuestions.count) Questions")
                    }
                }
            }
            .navigationTitle("Generate Questions")
            .navigationBarTitleDisplayMode(.large)
            .alert("Saved!", isPresented: $vm.showSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("\(vm.savedCount) questions added to your bank.")
            }
        }
    }
}

struct QuestionRowView: View {
    let question: Question
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation { expanded.toggle() }
            } label: {
                HStack(alignment: .top) {
                    Text(question.questionText)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            if expanded {
                ForEach(question.options, id: \.self) { opt in
                    HStack {
                        Text(opt)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                opt.hasPrefix(question.correctAnswer)
                                    ? Color.green.opacity(0.15)
                                    : Color.secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 6)
                            )
                            .foregroundStyle(
                                opt.hasPrefix(question.correctAnswer) ? .green : .primary
                            )
                    }
                }
                Text(question.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}
