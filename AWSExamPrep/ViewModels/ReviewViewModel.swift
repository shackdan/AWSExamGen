import Foundation
import SwiftData
import Observation

@Observable
final class ReviewViewModel {
    var items: [ReviewableQuestion] = []
    var isRunningBatchReview = false
    var showSaveSuccess = false
    var savedCount = 0
    private(set) var certType: String = ""

    private let llm  = LLMService.shared
    private let bank = QuestionBankService.shared

    var approvedCount: Int { items.filter { $0.status == .approved }.count }
    var pendingCount:  Int { items.filter { $0.status == .pending  }.count }
    var hasUnreviewed: Bool { items.contains { $0.review == nil && !$0.isReviewing } }

    func load(_ questions: [Question], certType: String) {
        self.certType = certType
        items = questions.map { ReviewableQuestion(question: $0) }
    }

    func approve(_ item: ReviewableQuestion) { item.status = .approved }
    func reject(_ item: ReviewableQuestion)  { item.status = .rejected  }
    func reset(_ item: ReviewableQuestion)   { item.status = .pending   }

    func approveAll() { items.forEach { $0.status = .approved } }

    func aiReview(_ item: ReviewableQuestion) async {
        guard !item.isReviewing else { return }
        item.isReviewing = true
        defer { item.isReviewing = false }
        do {
            let review = try await llm.reviewQuestion(item.question, certType: certType)
            item.review = review
            switch review.recommendation {
            case .approve: item.status = .approved
            case .reject:  item.status = .rejected
            case .revise:  break
            }
        } catch {
            // leave as pending; user can retry manually
        }
    }

    func aiReviewAll() async {
        isRunningBatchReview = true
        defer { isRunningBatchReview = false }
        await withTaskGroup(of: Void.self) { group in
            for item in items where item.review == nil {
                let captured = item
                group.addTask { await self.aiReview(captured) }
            }
        }
    }

    func saveApproved(context: ModelContext) throws {
        let toSave = items.filter { $0.status == .approved }.map { $0.question }
        try bank.save(toSave, to: context)
        savedCount = toSave.count
        showSaveSuccess = true
    }
}
