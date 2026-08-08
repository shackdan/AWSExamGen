import Foundation
import SwiftData

@Observable
final class QuestionBankService {

    static let shared = QuestionBankService()
    private init() {}

    // MARK: - SwiftData container
    @ObservationIgnored
    lazy var container: ModelContainer = {
        let schema = Schema([Question.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    // MARK: - Seed from bundled JSON on first launch
    func seedIfNeeded(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Question>())) ?? []
        guard existing.isEmpty else { return }

        guard
            let url  = Bundle.main.url(forResource: "question_bank", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return }

        struct BankFile: Codable { let questions: [Question] }
        if let bank = try? JSONDecoder().decode(BankFile.self, from: data) {
            bank.questions.forEach { context.insert($0) }
            try? context.save()
            print("QuestionBankService: Seeded \(bank.questions.count) questions ✅")
        }
    }

    // MARK: - CRUD helpers
    func save(_ questions: [Question], to context: ModelContext) throws {
        questions.forEach { context.insert($0) }
        try context.save()
    }

    func delete(_ question: Question, from context: ModelContext) throws {
        context.delete(question)
        try context.save()
    }

    func fetch(
        certType: String? = nil,
        topic: String? = nil,
        context: ModelContext
    ) throws -> [Question] {
        var descriptor = FetchDescriptor<Question>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        var predicates: [Predicate<Question>] = []
        if let cert = certType  { predicates.append(#Predicate { $0.certType == cert }) }
        if let t    = topic     { predicates.append(#Predicate { $0.topic    == t    }) }
        if !predicates.isEmpty  { descriptor.predicate = predicates.first }
        return try context.fetch(descriptor)
    }
}
