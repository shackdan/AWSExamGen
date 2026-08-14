import Foundation
import SwiftData
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
    func load(certType: String?, topic: String?, limit: Int, context: ModelContext) throws {
        var all = try QuestionBankService.shared.fetch(
            certType: certType == "" ? nil : certType,
            topic:    topic    == "" ? nil : topic,
            context:  context
        )
        all.shuffle()
        questions = Array(all.prefix(limit))
        reset()
    }

    // MARK: - Answer

    // For single-select: select and immediately submit.
    func selectAndSubmit(_ letter: String) {
        guard !hasAnswered else { return }
        selectedAnswers = [letter]
        finalize()
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

    // Finalize current answer (used by Submit button for multi-select).
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
