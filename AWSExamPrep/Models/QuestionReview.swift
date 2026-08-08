import Foundation
import Observation

enum ReviewStatus {
    case pending
    case approved
    case rejected
}

struct QuestionReview {
    enum Recommendation {
        case approve, revise, reject

        init(_ raw: String) {
            switch raw.lowercased().trimmingCharacters(in: .whitespaces) {
            case "approve": self = .approve
            case "reject":  self = .reject
            default:        self = .revise
            }
        }
    }

    let blueprintDomain: String
    let accuracyScore: Int       // 1–5
    let issues: [String]
    let suggestion: String
    let recommendation: Recommendation
}

@Observable
final class ReviewableQuestion: Identifiable {
    let id = UUID()
    let question: Question
    var status: ReviewStatus = .pending
    var review: QuestionReview? = nil
    var isReviewing = false

    init(question: Question) {
        self.question = question
    }
}
