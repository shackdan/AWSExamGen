import Foundation
import SwiftData
import Observation

@Observable
final class QuizViewModel {

    var questions: [Question] = []
    var results:   [QuizResult] = []
    var currentIndex = 0
    var selectedAnswer: String? = nil
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
    func submitAnswer(_ letter: String) {
        guard !hasAnswered, let q = current else { return }
        selectedAnswer = letter
        hasAnswered = true
        results.append(QuizResult(question: q, userAnswer: letter))
    }

    func next() {
        if currentIndex + 1 >= questions.count {
            isFinished = true
        } else {
            currentIndex += 1
            selectedAnswer = nil
            hasAnswered = false
        }
    }

    func reset() {
        currentIndex  = 0
        results       = []
        selectedAnswer = nil
        hasAnswered   = false
        isFinished    = false
    }

    // MARK: - Result grade
    var grade: (icon: String, title: String, color: String) {
        switch percentage {
        case 90...:  return ("🏆", "Outstanding!",         "correct")
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
