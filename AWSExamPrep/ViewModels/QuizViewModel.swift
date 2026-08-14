//
//  QuizViewModel.swift
//  AWSExamPrep
//
//  Copyright (c) 2026 Dan Newton
//  Licensed under CC BY-NC 4.0
//  https://creativecommons.org/licenses/by-nc/4.0/
//
//  You may share and adapt this code for non-commercial purposes only.
//  Attribution is required.
//
import Foundation
import Observation

@Observable
final class QuizViewModel {

    var questions: [Question] = []
    var results:   [QuizResult] = []
    var currentIndex = 0
    var selectedAnswers: Set<String> = []
    var hasAnswered = false
    var isFinished = false

    var current: Question? { questions[safe: currentIndex] }
    var progress: Double   { questions.isEmpty ? 0 : Double(currentIndex) / Double(questions.count) }
    var score: Int         { results.filter(\.isCorrect).count }
    var percentage: Double { questions.isEmpty ? 0 : Double(score) / Double(questions.count) * 100 }

    // MARK: - Load questions
    func load(certType: String?, topic: String?, limit: Int) {
        var all = QuestionBankService.shared.questions(
            certType: certType,
            topic:    topic
        )
        all.shuffle()
        questions = Array(all.prefix(limit))
        reset()
    }

    // MARK: - Answer

    // For single-select: highlight the choice without submitting yet.
    func selectOption(_ letter: String) {
        guard !hasAnswered else { return }
        selectedAnswers = [letter]
    }

    // For multi-select: toggle the given letter on/off.
    func toggleOption(_ letter: String) {
        guard !hasAnswered else { return }
        if selectedAnswers.contains(letter) {
            selectedAnswers.remove(letter)
        } else {
            selectedAnswers.insert(letter)
        }
    }

    // Finalize current answer (used by Submit button for all questions).
    func submitAnswer() {
        guard !hasAnswered, !selectedAnswers.isEmpty else { return }
        finalize()
    }

    private func finalize() {
        guard let q = current else { return }
        hasAnswered = true
        results.append(QuizResult(question: q, userAnswers: Array(selectedAnswers).sorted()))
    }

    func next() {
        if currentIndex + 1 >= questions.count {
            isFinished = true
        } else {
            currentIndex += 1
            selectedAnswers = []
            hasAnswered = false
        }
    }

    func reset() {
        currentIndex   = 0
        results        = []
        selectedAnswers = []
        hasAnswered    = false
        isFinished     = false
    }

    // MARK: - Result grade
    var grade: (icon: String, title: String, color: String) {
        switch percentage {
        case 90...:   return ("🏆", "Outstanding!",        "correct")
        case 80..<90: return ("🎉", "Excellent Work!",     "correct")
        case 70..<80: return ("✅", "Good Job — Passed!",  "correct")
        default:      return ("📚", "Keep Studying!",      "incorrect")
        }
    }
}

// Safe subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
