import SwiftUI
import SwiftData

struct ReviewView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let questions: [Question]
    let certType: String

    @State private var vm = ReviewViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                reviewProgressBar

                List(vm.items) { item in
                    ReviewQuestionCard(item: item, vm: vm)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .listStyle(.plain)

                saveBar
            }
            .navigationTitle("Review Questions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Dismiss") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            Task { await vm.aiReviewAll() }
                        } label: {
                            Label("AI Review All", systemImage: "sparkles")
                        }
                        .disabled(vm.isRunningBatchReview || !vm.hasUnreviewed)

                        Button {
                            vm.approveAll()
                        } label: {
                            Label("Approve All", systemImage: "checkmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .disabled(vm.isRunningBatchReview)
                }
            }
            .onAppear { vm.load(questions, certType: certType) }
            .alert("Saved!", isPresented: $vm.showSaveSuccess) {
                Button("Done") { dismiss() }
                Button("Keep Reviewing", role: .cancel) {}
            } message: {
                Text("\(vm.savedCount) question\(vm.savedCount == 1 ? "" : "s") added to your bank.")
            }
        }
    }

    // MARK: - Progress bar

    private var reviewProgressBar: some View {
        HStack(spacing: 16) {
            ReviewStatPill(count: vm.approvedCount, label: "Approved", color: .green)
            ReviewStatPill(count: vm.pendingCount,  label: "Pending",  color: .orange)
            ReviewStatPill(
                count: vm.items.filter { $0.status == .rejected }.count,
                label: "Rejected", color: .red
            )
            if vm.isRunningBatchReview {
                Spacer()
                ProgressView().tint(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    // MARK: - Save bar

    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                try? vm.saveApproved(context: context)
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save \(vm.approvedCount) Approved Question\(vm.approvedCount == 1 ? "" : "s")")
                        .bold()
                    Spacer()
                }
                .padding(.vertical, 14)
            }
            .disabled(vm.approvedCount == 0)
            .foregroundStyle(vm.approvedCount > 0 ? .white : .secondary)
            .background(vm.approvedCount > 0 ? Color.orange : Color.secondary.opacity(0.2))
        }
    }
}

// MARK: - Stat pill

private struct ReviewStatPill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Question card

struct ReviewQuestionCard: View {
    @Bindable var item: ReviewableQuestion
    let vm: ReviewViewModel
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                statusIcon
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.question.questionText)
                        .font(.subheadline)
                        .lineLimit(expanded ? nil : 2)
                        .foregroundStyle(.primary)

                    if let review = item.review {
                        blueprintDomainRow(review: review)
                    }
                }

                Spacer()

                Button { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } } label: {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if expanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: expanded)
    }

    // MARK: - Status icon

    @ViewBuilder
    private var statusIcon: some View {
        if item.isReviewing {
            ProgressView().frame(width: 20, height: 20)
        } else {
            switch item.status {
            case .approved:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .rejected:
                Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
            case .pending:
                Image(systemName: "circle").foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Blueprint domain row

    private func blueprintDomainRow(review: QuestionReview) -> some View {
        HStack(spacing: 6) {
            Image(systemName: accuracyIcon(review.accuracyScore))
                .font(.caption2)
                .foregroundStyle(accuracyColor(review.accuracyScore))
            Text(review.blueprintDomain)
                .font(.caption2.bold())
                .foregroundStyle(.purple)
            Text("·")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("Score \(review.accuracyScore)/5")
                .font(.caption2)
                .foregroundStyle(accuracyColor(review.accuracyScore))
        }
    }

    // MARK: - Expanded content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Options
            VStack(alignment: .leading, spacing: 4) {
                ForEach(item.question.options, id: \.self) { opt in
                    let isCorrect = opt.hasPrefix(item.question.correctAnswer)
                    HStack(spacing: 8) {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "circle")
                            .font(.caption)
                            .foregroundStyle(isCorrect ? .green : .secondary)
                        Text(opt)
                            .font(.caption)
                            .foregroundStyle(isCorrect ? .green : .primary)
                            .bold(isCorrect)
                    }
                }
            }

            Divider()

            // Explanation
            Text(item.question.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)

            // AI review feedback
            if let review = item.review {
                aiReviewFeedback(review: review)
            }

            // Action buttons
            actionButtons
        }
        .padding(.leading, 34)
    }

    // MARK: - AI feedback block

    private func aiReviewFeedback(review: QuestionReview) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            Label("AI Review", systemImage: "sparkles")
                .font(.caption.bold())
                .foregroundStyle(.purple)

            if !review.issues.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(review.issues, id: \.self) { issue in
                        Label(issue, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }

            if !review.suggestion.isEmpty {
                Text(review.suggestion)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
    }

    // MARK: - Action buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            switch item.status {
            case .pending:
                Button { vm.approve(item) } label: {
                    Label("Approve", systemImage: "checkmark")
                        .font(.caption.bold())
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
                Button { vm.reject(item) } label: {
                    Label("Reject", systemImage: "xmark")
                        .font(.caption.bold())
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.red.opacity(0.12))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                }
            case .approved:
                Button { vm.reset(item) } label: {
                    Label("Undo", systemImage: "arrow.uturn.left")
                        .font(.caption.bold())
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.12))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())
                }
            case .rejected:
                Button { vm.reset(item) } label: {
                    Label("Undo", systemImage: "arrow.uturn.left")
                        .font(.caption.bold())
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.12))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())
                }
            }

            if item.review == nil && !item.isReviewing {
                Spacer()
                Button {
                    Task { await vm.aiReview(item) }
                } label: {
                    Label("AI Review", systemImage: "sparkles")
                        .font(.caption.bold())
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.purple.opacity(0.12))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Helpers

    private func accuracyIcon(_ score: Int) -> String {
        switch score {
        case 5:    return "checkmark.seal.fill"
        case 4:    return "checkmark.circle"
        case 3:    return "minus.circle"
        default:   return "exclamationmark.triangle"
        }
    }

    private func accuracyColor(_ score: Int) -> Color {
        switch score {
        case 5, 4: return .green
        case 3:    return .orange
        default:   return .red
        }
    }
}
