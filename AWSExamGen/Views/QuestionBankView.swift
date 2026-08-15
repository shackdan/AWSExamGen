//
//  QuestionBankView.swift
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

struct QuestionBankView: View {
    @State private var certFilter  = ""
    @State private var topicFilter = ""
    @State private var searchText  = ""

    private var allQuestions: [Question] { QuestionBankService.shared.allQuestions }
    var uniqueCerts:  [String] { QuestionBankService.shared.availableCerts }
    var uniqueTopics: [String] { QuestionBankService.shared.availableTopics }

    var filtered: [Question] {
        allQuestions.filter { q in
            (certFilter.isEmpty  || q.certType == certFilter) &&
            (topicFilter.isEmpty || q.topic    == topicFilter) &&
            (searchText.isEmpty  ||
             q.questionText.localizedCaseInsensitiveContains(searchText) ||
             q.topic.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if QuestionBankService.shared.isLoading {
                    ProgressView("Loading question bank…")
                } else if allQuestions.isEmpty {
                    ContentUnavailableView(
                        "No Questions Yet",
                        systemImage: "archivebox",
                        description: Text("Add .json files to the question_bank folder in Xcode and rebuild.")
                    )
                } else {
                    let filtered = filtered
                    List {
                        // Filter chips
                        Section {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(label: "All Certs",
                                               isSelected: certFilter.isEmpty) {
                                        certFilter = ""
                                    }
                                    ForEach(uniqueCerts, id: \.self) { cert in
                                        FilterChip(label: cert,
                                                   isSelected: certFilter == cert) {
                                            certFilter = certFilter == cert ? "" : cert
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    FilterChip(label: "All Topics",
                                               isSelected: topicFilter.isEmpty) {
                                        topicFilter = ""
                                    }
                                    ForEach(uniqueTopics, id: \.self) { topic in
                                        FilterChip(label: topic,
                                                   isSelected: topicFilter == topic) {
                                            topicFilter = topicFilter == topic ? "" : topic
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                        // Count
                        Section {
                            Text("\(filtered.count) question\(filtered.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .listRowBackground(Color.clear)

                        // Questions
                        ForEach(filtered) { q in
                            BankQuestionRow(question: q)
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search questions…")
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Question Bank")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Bank row
struct BankQuestionRow: View {
    let question: Question
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(question.certType)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.blue.opacity(0.12))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                            Text(question.topic)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.purple.opacity(0.12))
                                .foregroundStyle(.purple)
                                .clipShape(Capsule())
                            if question.isMultiSelect {
                                Text("Multi")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.12))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(question.questionText)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(expanded ? nil : 2)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if expanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(question.options, id: \.self) { opt in
                        let isCorrect = question.isCorrectOption(Question.letter(fromOption: opt))
                        HStack(spacing: 8) {
                            Image(systemName: isCorrect
                                  ? "checkmark.circle.fill"
                                  : "circle")
                                .font(.caption)
                                .foregroundStyle(isCorrect ? .green : .secondary)
                            Text(opt)
                                .font(.caption)
                                .foregroundStyle(isCorrect ? .green : .primary)
                                .bold(isCorrect)
                        }
                    }

                    Divider()

                    Text("💡 \(question.explanation)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Filter chip
struct FilterChip: View {
    let label:      String
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.orange : Color.secondary.opacity(0.12))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
