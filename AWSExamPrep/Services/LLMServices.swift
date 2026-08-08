import Foundation
import CoreML
import NaturalLanguage
import FoundationModels

// ---------------------------------------------------------------------------
// LLMService — abstraction over local vs. cloud inference
//
// PRIORITY ORDER:
//  1. Apple Intelligence (FoundationModels) — on-device, zero bundle overhead,
//     requires Apple Intelligence enabled (A17 Pro / M-series, iOS 26+)
//  2. Core ML .mlpackage — bring-your-own open-weight model (Gemma 3n, Qwen3,
//     Phi-3, etc.). Convert with coremltools and add to the bundle.
//  3. OpenAI API — cloud fallback when no local model is present.
// ---------------------------------------------------------------------------

enum LLMBackend {
    case appleIntelligence
    case local
    case openAI(key: String)
}

enum LLMError: LocalizedError {
    case noModelLoaded
    case invalidResponse
    case networkError(String)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .noModelLoaded:       return "No local model loaded. Add an OpenAI key or install a Core ML model."
        case .invalidResponse:     return "The model returned an unexpected response."
        case .networkError(let m): return "Network error: \(m)"
        case .parseError(let m):   return "Could not parse questions: \(m)"
        }
    }
}

// MARK: - FoundationModels structured output types (iOS 26+)

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@Generable(description: "A set of AWS exam practice questions")
private struct GeneratedQuestionSet {
    @Guide(description: "The list of practice questions")
    var questions: [GeneratedQuestion]
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@Generable(description: "A single multiple-choice AWS exam practice question")
private struct GeneratedQuestion {
    @Guide(description: "The question text, scenario-based and realistic")
    var question: String

    @Guide(description: "Exactly 4 answer options formatted as: 'A) text', 'B) text', 'C) text', 'D) text'")
    var options: [String]

    @Guide(description: "The letter of the correct answer: A, B, C, or D")
    var correctAnswer: String

    @Guide(description: "Detailed explanation of why the answer is correct and the others are not")
    var explanation: String

    @Guide(description: "A URL to the official AWS documentation page most relevant to this question's topic (e.g. https://docs.aws.amazon.com/...)")
    var referenceURL: String
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@Generable(description: "An accuracy and blueprint-alignment review of an AWS exam practice question")
private struct GeneratedQuestionReview {
    @Guide(description: "The exam blueprint domain this question best maps to (e.g. 'Design Secure Architectures')")
    var blueprintDomain: String

    @Guide(description: "Accuracy score 1–5: 5 = fully correct, 4 = minor imprecision, 3 = debatable, 2 = significant errors, 1 = critically wrong")
    var accuracyScore: Int

    @Guide(description: "Specific factual or structural issues with the question. Empty array if none.")
    var issues: [String]

    @Guide(description: "A one-sentence improvement suggestion, or an empty string if the question is good as-is.")
    var suggestion: String

    @Guide(description: "Overall recommendation: 'approve' if accurate and blueprint-aligned, 'revise' if fixable issues exist, 'reject' if fundamentally incorrect.")
    var recommendation: String
}

// MARK: - LLMService

@Observable
final class LLMService {

    // MARK: - State
    var backend: LLMBackend = .local
    var isLoading = false
    var loadedModelName: String? = nil

    var backendDescription: String {
        guard loadedModelName != nil else {
            return "Add a Core ML .mlpackage to the bundle to enable on-device inference"
        }
        if case .appleIntelligence = backend {
            return "Apple Neural Engine · On-device · Private"
        }
        return "Neural Engine · On-device · Private"
    }

    // MARK: - Core ML model handle
    // Replace the resource name below with your converted .mlpackage.
    // Gemma 3n 2B and Qwen3-0.6B are good choices for on-device inference.
    // See: https://huggingface.co/docs/optimum/apple/guides/coreml
    private var coreMLModel: MLModel?

    // MARK: - Singleton
    static let shared = LLMService()
    private init() {
        // Prefer Apple Intelligence — zero bundle size, fastest, most private.
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            if SystemLanguageModel.default.availability == .available {
                loadedModelName = "Apple Intelligence (on-device)"
                backend = .appleIntelligence
                return
            }
        }
        // Fall back to a bundled/downloaded Core ML model.
        tryLoadLocalModel()
    }

    // MARK: - Load local Core ML model
    private func tryLoadLocalModel() {
        guard let modelURL = Bundle.main.url(
            forResource: "phi3-mini-4k-instruct",
            withExtension: "mlpackage"
        ) else {
            print("LLMService: No local .mlpackage found — will use OpenAI fallback.")
            return
        }

        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine
            coreMLModel = try MLModel(contentsOf: modelURL, configuration: config)
            loadedModelName = "Phi-3 mini (on-device)"
            backend = .local
            print("LLMService: Loaded local Core ML model ✅")
        } catch {
            print("LLMService: Failed to load Core ML model — \(error)")
        }
    }

    // MARK: - Public API
    func generateQuestions(_ config: GenerateConfig) async throws -> [Question] {
        isLoading = true
        defer { isLoading = false }

        switch backend {
        case .appleIntelligence:
            if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
                return try await generateAppleIntelligence(config)
            }
            throw LLMError.noModelLoaded
        case .local:
            return try await generateLocal(config)
        case .openAI(let key):
            return try await generateOpenAI(config, apiKey: key)
        }
    }

    // MARK: - Apple Intelligence via FoundationModels (iOS 26+)
    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    private func generateAppleIntelligence(_ config: GenerateConfig) async throws -> [Question] {
        let session = LanguageModelSession(instructions: """
            You are an AWS certification exam expert. \
            Generate realistic, scenario-based multiple-choice practice questions \
            with exactly 4 options each.
            """)

        let topicStr = config.topic == "General" ? "" : " focusing on \(config.topic)"
        let prompt = "Generate \(config.numQuestions) AWS \(config.certType) exam practice questions\(topicStr)."

        let response = try await session.respond(to: prompt, generating: GeneratedQuestionSet.self)

        return response.content.questions.map { q in
            Question(
                questionText: q.question,
                options: q.options,
                correctAnswer: q.correctAnswer,
                explanation: q.explanation,
                certType: config.certType,
                topic: config.topic,
                referenceURL: q.referenceURL.isEmpty ? nil : q.referenceURL
            )
        }
    }

    // MARK: - Local inference via Core ML
    private func generateLocal(_ config: GenerateConfig) async throws -> [Question] {
        guard let model = coreMLModel else { throw LLMError.noModelLoaded }

        let prompt = buildPrompt(config)
        let inputFeatures = try MLDictionaryFeatureProvider(dictionary: [
            "prompt": MLFeatureValue(string: prompt)
        ])

        // Capture model to avoid crossing actor boundaries inside Task.detached.
        let result = try await Task.detached(priority: .userInitiated) {
            try model.prediction(from: inputFeatures)
        }.value

        guard let outputText = result.featureValue(for: "output")?.stringValue else {
            throw LLMError.invalidResponse
        }

        return try QuestionParser.parse(outputText, certType: config.certType, topic: config.topic)
    }

    // MARK: - OpenAI cloud fallback
    private func generateOpenAI(_ config: GenerateConfig, apiKey: String) async throws -> [Question] {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json",  forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system",
                 "content": "You are an AWS certification exam expert. Generate realistic practice questions. Always respond with valid JSON only."],
                ["role": "user", "content": buildPrompt(config)]
            ]
        ]

        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw LLMError.networkError("HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        struct OAIResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }

        let oaiResp = try JSONDecoder().decode(OAIResponse.self, from: data)
        guard let content = oaiResp.choices.first?.message.content else {
            throw LLMError.invalidResponse
        }

        return try QuestionParser.parse(content, certType: config.certType, topic: config.topic)
    }

    // MARK: - Public review API

    func reviewQuestion(_ question: Question, certType: String) async throws -> QuestionReview {
        let blueprint = examBlueprints[certType]
        let domainsText = blueprint?.domains
            .map { "- \($0.name) (\(Int($0.weight))%)" }
            .joined(separator: "\n") ?? "No blueprint data available."

        switch backend {
        case .appleIntelligence:
            if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
                return try await reviewAppleIntelligence(question, domainsText: domainsText)
            }
            throw LLMError.noModelLoaded
        case .openAI(let key):
            return try await reviewOpenAI(question, certType: certType, domainsText: domainsText, apiKey: key)
        case .local:
            throw LLMError.noModelLoaded
        }
    }

    // MARK: - Review via Apple Intelligence

    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    private func reviewAppleIntelligence(_ question: Question, domainsText: String) async throws -> QuestionReview {
        let session = LanguageModelSession(instructions: """
            You are an AWS certification exam expert and exam blueprint analyst. \
            Evaluate practice questions for technical accuracy and blueprint alignment.
            """)

        let prompt = buildReviewPrompt(question, domainsText: domainsText)
        let response = try await session.respond(to: prompt, generating: GeneratedQuestionReview.self)
        let r = response.content
        return QuestionReview(
            blueprintDomain: r.blueprintDomain,
            accuracyScore: max(1, min(5, r.accuracyScore)),
            issues: r.issues,
            suggestion: r.suggestion,
            recommendation: QuestionReview.Recommendation(r.recommendation)
        )
    }

    // MARK: - Review via OpenAI

    private func reviewOpenAI(_ question: Question, certType: String, domainsText: String, apiKey: String) async throws -> QuestionReview {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json",  forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system",
                 "content": "You are an AWS certification exam expert. Review practice questions for accuracy and blueprint alignment. Respond with valid JSON only."],
                ["role": "user", "content": buildReviewPrompt(question, domainsText: domainsText)]
            ]
        ]

        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw LLMError.networkError("HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }

        struct OAIResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }
        struct ReviewPayload: Codable {
            let blueprintDomain: String
            let accuracyScore: Int
            let issues: [String]
            let suggestion: String
            let recommendation: String
            enum CodingKeys: String, CodingKey {
                case blueprintDomain = "blueprint_domain"
                case accuracyScore = "accuracy_score"
                case issues, suggestion, recommendation
            }
        }

        let oaiResp = try JSONDecoder().decode(OAIResponse.self, from: data)
        guard let content = oaiResp.choices.first?.message.content,
              let payloadData = content.data(using: .utf8),
              let payload = try? JSONDecoder().decode(ReviewPayload.self, from: payloadData)
        else { throw LLMError.invalidResponse }

        return QuestionReview(
            blueprintDomain: payload.blueprintDomain,
            accuracyScore: max(1, min(5, payload.accuracyScore)),
            issues: payload.issues,
            suggestion: payload.suggestion,
            recommendation: QuestionReview.Recommendation(payload.recommendation)
        )
    }

    // MARK: - Review prompt

    private func buildReviewPrompt(_ question: Question, domainsText: String) -> String {
        """
        Review the following AWS \(question.certType) practice question for technical accuracy \
        and alignment with the exam blueprint domains listed below.

        EXAM BLUEPRINT DOMAINS:
        \(domainsText)

        QUESTION:
        \(question.questionText)

        OPTIONS:
        \(question.options.joined(separator: "\n"))

        MARKED CORRECT ANSWER: \(question.correctAnswer)

        EXPLANATION:
        \(question.explanation)

        Evaluate:
        1. Is the marked answer factually correct?
        2. Which blueprint domain does this question best map to?
        3. Are there any technical inaccuracies or ambiguities?
        4. Is the difficulty level appropriate for the \(question.certType) exam?

        Respond with JSON:
        {
          "blueprint_domain": "domain name from the list above",
          "accuracy_score": 5,
          "issues": ["issue 1", "issue 2"],
          "suggestion": "brief improvement suggestion or empty string",
          "recommendation": "approve"
        }
        """
    }

    // MARK: - Prompt builder (for Core ML / OpenAI paths)
    private func buildPrompt(_ config: GenerateConfig) -> String {
        let topicStr = config.topic == "General" ? "" : " focusing on \(config.topic)"
        return """
        Generate \(config.numQuestions) AWS \(config.certType) exam practice questions\(topicStr).

        Each question must:
        - Be multiple choice with exactly 4 options (A, B, C, D)
        - Be scenario-based and realistic
        - Have exactly one correct answer
        - Include a detailed explanation
        - Include a reference_url pointing to the most relevant official AWS documentation page (https://docs.aws.amazon.com/...)

        Return ONLY valid JSON:
        {
          "questions": [
            {
              "question": "question text",
              "options": ["A) option1", "B) option2", "C) option3", "D) option4"],
              "correct_answer": "A",
              "explanation": "detailed explanation",
              "reference_url": "https://docs.aws.amazon.com/..."
            }
          ]
        }
        """
    }
}
