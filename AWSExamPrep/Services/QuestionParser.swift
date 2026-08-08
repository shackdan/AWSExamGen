import Foundation

enum QuestionParser {

    // Parses raw JSON string from either local or cloud model output
    static func parse(_ raw: String, certType: String, topic: String) throws -> [Question] {

        // Strip markdown code fences if model wraps output in ```json ... ```
        let cleaned = raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```",     with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw LLMError.parseError("Could not encode response as UTF-8")
        }

        struct RawResponse: Codable {
            struct RawQuestion: Codable {
                let question: String
                let options: [String]
                let correct_answer: String
                let explanation: String
                let reference_url: String?
            }
            let questions: [RawQuestion]
        }

        do {
            let resp = try JSONDecoder().decode(RawResponse.self, from: data)
            return resp.questions.map { rq in
                Question(
                    questionText:  rq.question,
                    options:       rq.options,
                    correctAnswer: rq.correct_answer,
                    explanation:   rq.explanation,
                    certType:      certType,
                    topic:         topic,
                    referenceURL:  rq.reference_url
                )
            }
        } catch {
            throw LLMError.parseError(error.localizedDescription)
        }
    }
}
