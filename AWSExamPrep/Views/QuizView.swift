import SwiftUI
import SwiftData

struct QuizView: View {
    @Environment(\.modelContext) private var context
    @State private var vm = QuizViewModel()
    @State private var certFilter  = ""
    @State private var topicFilter = ""
    @State private var limit = 10
    @State private var quizStarted = false
    @State private var loadError: String? = nil

    @Query private var allQuestions: [Question]

    var uniqueCerts:  [String] { Array(Set(allQuestions.map(\.certType))).sorted() }
    var uniqueTopics: [String] { Array(Set(allQuestions.map(\.topic))).sorted() }

    var body: some View {
        NavigationStack {
            if !quizStarted {
                setupView
            } else if vm.isFinished {
                resultsView
            } else {
                quizActiveView
            }
        }
    }

    // MARK: - Setup
    var setupView: some View {
        Form {
            Section {
                Picker("Certification", selection: $certFilter) {
                    Text("All").tag("")
                    ForEach(uniqueCerts, id: \.self) { Text($0).tag($0) }
                }
                Picker("Topic", selection: $topicFilter) {
                    Text("All").tag("")
                    ForEach(uniqueTopics, id: \.self) { Text($0).tag($0) }
                }
                Stepper("Questions: \(limit)", value: $limit, in: 5...25, step: 5)
            } header: { Text("Quiz Settings") }

            if let err = loadError {
                Section {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    startQuiz()
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "play.fill")
                        Text("Start Quiz").bold()
                        Spacer()
                    }
                }
                .listRowBackground(Color.orange)
                .foregroundStyle(.white)
                .disabled(allQuestions.isEmpty)
            }

            if allQuestions.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Questions Yet",
                        systemImage: "questionmark.folder",
                        description: Text("Add .md question files to the question_bank folder in Xcode and rebuild.")
                    )
                }
            }
        }
        .navigationTitle("Quiz")
    }

    // MARK: - Active Quiz
    var quizActiveView: some View {
        VStack(spacing: 0) {
            // Progress bar
            VStack(spacing: 6) {
                HStack {
                    Text("Question \(vm.currentIndex + 1) of \(vm.questions.count)")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Text("Score: \(vm.score) / \(vm.results.count)")
                        .font(.subheadline.bold()).foregroundStyle(.orange)
                }
                ProgressView(value: vm.progress)
                    .tint(.orange)
            }
            .padding()
            .background(.bar)

            if let q = vm.current {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Cert / topic badges
                        HStack {
                            Text(q.certType)
                                .font(.caption.bold())
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(.blue.opacity(0.12))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                            Text(q.topic)
                                .font(.caption.bold())
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(.purple.opacity(0.12))
                                .foregroundStyle(.purple)
                                .clipShape(Capsule())
                        }

                        // Question text
                        Text(q.questionText)
                            .font(.title3.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)

                        // Multi-select hint
                        if q.isMultiSelect {
                            Label("Select all correct answers, then tap Submit", systemImage: "checkmark.square")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Options
                        VStack(spacing: 12) {
                            ForEach(q.options, id: \.self) { option in
                                let letter = String(option.prefix(1))
                                OptionButton(
                                    option: option,
                                    letter: letter,
                                    state: optionState(letter: letter, question: q),
                                    disabled: vm.hasAnswered
                                ) {
                                    if q.isMultiSelect {
                                        vm.toggleOption(letter)
                                    } else {
                                        vm.selectAndSubmit(letter)
                                    }
                                }
                            }
                        }

                        // Submit button (multi-select only, before answering)
                        if q.isMultiSelect && !vm.hasAnswered {
                            Button {
                                withAnimation { vm.submitAnswer() }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Submit Answer").bold()
                                    Spacer()
                                }
                                .padding()
                                .background(vm.selectedAnswers.isEmpty ? Color(.systemGray4) : Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(vm.selectedAnswers.isEmpty)
                        }

                        // Feedback + Next
                        if vm.hasAnswered {
                            FeedbackCard(
                                isCorrect: vm.results.last?.isCorrect ?? false,
                                correctAnswer: q.correctAnswer,
                                explanation: q.explanation,
                                referenceURL: q.referenceURL
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            Button {
                                withAnimation { vm.next() }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text(vm.currentIndex + 1 >= vm.questions.count
                                         ? "See Results"
                                         : "Next Question")
                                        .bold()
                                    Image(systemName: vm.currentIndex + 1 >= vm.questions.count
                                          ? "flag.checkered"
                                          : "arrow.right")
                                    Spacer()
                                }
                                .padding()
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding()
                    .animation(.easeInOut(duration: 0.3), value: vm.hasAnswered)
                }
            }
        }
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Quit") {
                    withAnimation {
                        quizStarted = false
                        vm.reset()
                    }
                }
                .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Results
    var resultsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Grade card
                VStack(spacing: 12) {
                    Text(vm.grade.icon)
                        .font(.system(size: 72))
                    Text(vm.grade.title)
                        .font(.largeTitle.bold())
                    Text("\(vm.score) out of \(vm.questions.count) correct")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f%%", vm.percentage))
                        .font(.system(size: 56, weight: .black))
                        .foregroundStyle(vm.percentage >= 70 ? .green : .red)
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        withAnimation { startQuiz() }
                    } label: {
                        Label("Try Again", systemImage: "arrow.counterclockwise")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    Button {
                        withAnimation {
                            quizStarted = false
                            vm.reset()
                        }
                    } label: {
                        Label("New Quiz Settings", systemImage: "slider.horizontal.3")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.secondary.opacity(0.15))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                // Review answers
                VStack(alignment: .leading, spacing: 12) {
                    Text("Review Answers")
                        .font(.title3.bold())
                        .padding(.horizontal)
                    ForEach(Array(vm.results.enumerated()), id: \.offset) { i, result in
                        ReviewCard(index: i + 1, result: result)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Results")
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Helpers
    func startQuiz() {
        do {
            try vm.load(
                certType: certFilter,
                topic: topicFilter,
                limit: limit,
                context: context
            )
            if vm.questions.isEmpty {
                loadError = "No questions match your filters."
            } else {
                loadError = nil
                quizStarted = true
            }
        } catch {
            loadError = error.localizedDescription
        }
    }

    func optionState(letter: String, question: Question) -> OptionState {
        if vm.hasAnswered {
            if question.isCorrectOption(letter) { return .correct }
            if vm.selectedAnswers.contains(letter) { return .incorrect }
            return .unanswered
        }
        return vm.selectedAnswers.contains(letter) ? .selected : .unanswered
    }
}
