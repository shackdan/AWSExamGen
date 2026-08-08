import Foundation
import SwiftData
import Observation

@Observable
final class GenerateViewModel {

    var config = GenerateConfig()
    var generatedQuestions: [Question] = []
    var isGenerating = false
    var errorMessage: String? = nil
    var showReview = false

    private let llm = LLMService.shared

    var isLocalModel: Bool { llm.loadedModelName != nil }
    var modelName: String  { llm.loadedModelName ?? "OpenAI GPT-4o-mini" }

    func generate() async {
        isGenerating = true
        errorMessage = nil
        generatedQuestions = []

        do {
            let questions = try await llm.generateQuestions(config)
            generatedQuestions = questions
            showReview = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }
}
