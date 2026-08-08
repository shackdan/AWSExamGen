import SwiftUI
import SwiftData

struct QuestionBankView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Question.createdAt, order: .reverse) private var allQuestions: [Question]

    @State private var certFilter  = ""
    @State private var topicFilter = ""
    @State private var searchText  = ""
    @State private var showDeleteConfirm = false
    @State private var questionToDelete: Question? = nil

    var uniqueCerts:  [String] { Array(Set(allQuestions.map(\.certType))).sorted() }
    var uniqueTopics: [String] { Array(Set(allQuestions.map(\.topic))).sorted() }

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
                if allQuestions.isEmpty {
                    ContentUnavailableView(
                        "No Questions Yet",
                        systemImage: "archivebox",
                        description: Text("Generate questions and save them to your bank.")
                    )
                } else {
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
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        questionToDelete = q
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search questions…")
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Question Bank")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog(
                "Delete this question?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let q = questionToDelete {
                        try? QuestionBankService.shared.delete(q, from: context)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
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
                        let isCorrect = opt.hasPrefix(question.correctAnswer)
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
