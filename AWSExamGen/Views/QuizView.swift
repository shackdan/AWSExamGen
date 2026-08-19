//
//  QuizView.swift
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

struct QuizView: View {
    @State private var vm = QuizViewModel()
    @State private var certFilter  = ""
    @State private var topicFilter = ""
    @State private var limit = 10
    @State private var quizStarted = false
    @State private var loadError: String? = nil

    private var bank: QuestionBankService { QuestionBankService.shared }
    var uniqueCerts:  [String] { bank.availableCerts }
    var uniqueTopics: [String] { bank.availableTopics(forCert: certFilter.isEmpty ? nil : certFilter) }

    var body: some View {
        NavigationStack {
            if bank.isLoading {
                ProgressView("Loading question bank…")
            } else if !quizStarted {
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
                Picker("Domain", selection: $topicFilter) {
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
                .disabled(bank.allQuestions.isEmpty)
            }

            if bank.allQuestions.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Questions Yet",
                        systemImage: "questionmark.folder",
                        description: Text("Add .json files to the question_bank folder in Xcode and rebuild.")
                    )
                }
            }
        }
        .navigationTitle("Quiz")
        .onChange(of: certFilter) {
            if !topicFilter.isEmpty, !uniqueTopics.contains(topicFilter) {
                topicFilter = ""
            }
        }
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
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Color.clear.frame(height: 0).id("questionTop")

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

                            // Question type hint
                            if q.isMultiSelect {
                                Label("Select all that apply, then tap Submit", systemImage: "checkmark.square")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Label("Choose one answer, then tap Submit", systemImage: "circle")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            // Options
                            VStack(spacing: 12) {
                                ForEach(q.options, id: \.self) { option in
                                    let letter = Question.letter(fromOption: option)
                                    OptionButton(
                                        option: option,
                                        letter: letter,
                                        state: optionState(letter: letter, question: q),
                                        isMultiSelect: q.isMultiSelect,
                                        disabled: vm.hasAnswered
                                    ) {
                                        if q.isMultiSelect {
                                            vm.toggleOption(letter)
                                        } else {
                                            vm.selectOption(letter)
                                        }
                                    }
                                }
                            }

                            // Submit button (all question types, before answering)
                            if !vm.hasAnswered {
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
                    .onChange(of: vm.currentIndex) {
                        proxy.scrollTo("questionTop", anchor: .top)
                    }
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
        vm.load(
            certType: certFilter.isEmpty ? nil : certFilter,
            topic:    topicFilter.isEmpty ? nil : topicFilter,
            limit:    limit
        )
        if vm.questions.isEmpty {
            loadError = "No questions match your filters."
        } else {
            loadError = nil
            quizStarted = true
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
