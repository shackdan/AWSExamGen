//
//  QuestionParser.swift
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

enum MarkdownQuestionParser {

    // MARK: - Public API

    static func parse(fileURL: URL) -> [Question] {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return [] }
        return parse(markdown: content, filename: fileURL.deletingPathExtension().lastPathComponent)
    }

    // MARK: - JSON parsing

    static func parseJSON(fileURL: URL) -> [Question] {
        guard let data = try? Data(contentsOf: fileURL),
              !data.isEmpty,
              data.first != 0 else { return [] }

        let filename = fileURL.deletingPathExtension().lastPathComponent
        let fileCertType = inferCertType(from: filename)

        // Try new format (object with metadata + questions array) first
        if let file = try? JSONDecoder().decode(NewFormatFile.self, from: data) {
            let certType = file.metadata?.cert_code ?? fileCertType
            let questions = file.questions.compactMap { r -> Question? in
                let answer = r.correct_answers
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { ["A", "B", "C", "D"].contains($0) }
                    .joined(separator: " and ")
                guard !r.question_text.isEmpty, r.options.count >= 2, !answer.isEmpty else { return nil }
                return Question(
                    questionText: r.question_text,
                    options: r.options,
                    correctAnswer: answer,
                    explanation: r.explanation,
                    certType: r.cert_code ?? certType,
                    topic: r.domain ?? "General",
                    referenceURL: r.source_url
                )
            }
            return deduplicate(questions)
        }

        // Fall back to old flat-array format
        guard let rawQuestions = try? JSONDecoder().decode([OldFormatQuestion].self, from: data) else { return [] }
        let questions = rawQuestions.compactMap { r -> Question? in
            let answer = normalizeAnswer(r.correct_answer)
            guard !r.question.isEmpty, r.options.count >= 2, !answer.isEmpty else { return nil }
            return Question(
                questionText: r.question,
                options: r.options,
                correctAnswer: answer,
                explanation: r.explanation,
                certType: r.cert_type ?? fileCertType,
                topic: r.topic ?? "General",
                referenceURL: r.reference_url
            )
        }
        return deduplicate(questions)
    }

    // New format: { metadata: {...}, questions: [...] }
    private struct NewFormatFile: Decodable {
        let metadata: NewFormatMetadata?
        let questions: [NewFormatQuestion]

        struct NewFormatMetadata: Decodable {
            let cert_code: String?
        }

        struct NewFormatQuestion: Decodable {
            let question_text: String
            let options: [String]
            let correct_answers: [String]
            let explanation: String
            let cert_code: String?
            let domain: String?
            let source_url: String?
        }
    }

    // Old format: top-level array
    private struct OldFormatQuestion: Decodable {
        let question: String
        let options: [String]
        let correct_answer: String
        let explanation: String
        let cert_type: String?
        let topic: String?
        let reference_url: String?
    }

    static func parse(markdown: String, filename: String = "") -> [Question] {
        let certType = extractCertType(from: markdown) ?? inferCertType(from: filename)
        let lines = markdown.components(separatedBy: "\n")

        // Collect indices where question blocks start
        var starts: [Int] = []
        for (i, line) in lines.enumerated() {
            if isQuestionHeader(line.trimmingCharacters(in: .whitespaces)) {
                starts.append(i)
            }
        }

        guard !starts.isEmpty else { return [] }

        var questions: [Question] = []
        for (idx, start) in starts.enumerated() {
            let end = idx + 1 < starts.count ? starts[idx + 1] : lines.count
            let block = Array(lines[start..<end])
            if let q = parseBlock(block, certType: certType) {
                questions.append(q)
            }
        }

        return deduplicate(questions)
    }

    // MARK: - Question header detection

    private static func isQuestionHeader(_ line: String) -> Bool {
        let patterns = [
            #"^\*\*Question \d+"#,   // **Question N:**
            #"^#{1,4} Question \d+"# // ### Question N:
        ]
        return patterns.contains { line.range(of: $0, options: .regularExpression) != nil }
    }

    // MARK: - Cert type extraction

    private static func extractCertType(from markdown: String) -> String? {
        for line in markdown.components(separatedBy: "\n") where line.contains("Certification:") {
            if let range = line.range(of: #"\([A-Z]+-[A-Z0-9]+\)"#, options: .regularExpression) {
                return String(line[range].dropFirst().dropLast())
            }
        }
        return nil
    }

    private static func inferCertType(from filename: String) -> String {
        let lc = filename.lowercased()
        let map: [String: String] = [
            "sap-c02": "SAP-C02", "sap_c02": "SAP-C02",
            "saa-c03": "SAA-C03", "saa_c03": "SAA-C03",
            "dva-c02": "DVA-C02", "dva_c02": "DVA-C02",
            "clf-c02": "CLF-C02", "clf_c02": "CLF-C02",
            "soa-c02": "SOA-C02", "soa_c02": "SOA-C02",
            "dop-c02": "DOP-C02", "dop_c02": "DOP-C02",
            "ans-c01": "ANS-C01", "ans_c01": "ANS-C01",
            "aif-c01": "AIF-C01", "aif_c01": "AIF-C01",
            "mls-c01": "MLS-C01", "mls_c01": "MLS-C01",
            "mla-c01": "MLA-C01", "mla_c01": "MLA-C01",
            "dea-c01": "DEA-C01", "dea_c01": "DEA-C01",
            "scs-c02": "SCS-C02", "scs_c02": "SCS-C02",
            "pas-c01": "PAS-C01", "pas_c01": "PAS-C01"
        ]
        return map.first(where: { lc.contains($0.key) })?.value ?? "SAA-C03"
    }

    // MARK: - Block parsing

    private static func parseBlock(_ lines: [String], certType: String) -> Question? {
        var domain = "General"
        var questionParts: [String] = []
        var options: [String] = []
        var correctAnswer = ""
        var explanationParts: [String] = []
        // 0=pre-question  1=question  2=options  3=explanation  4=done
        var phase = 0

        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            guard !t.isEmpty, phase < 4 else { continue }

            // End of useful content markers
            if isStopMarker(t, phase: phase) { phase = 4; break }

            // Skip structural lines
            if isQuestionHeader(t) || t.hasPrefix("#") || t == "---" { continue }

            // Domain line  (**Domain:** ... or **Domain: ...**)
            if t.hasPrefix("**Domain") {
                let raw = t
                    .replacingOccurrences(of: "**Domain:**", with: "")
                    .replacingOccurrences(of: "**Domain:", with: "")
                    .replacingOccurrences(of: "**", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if !raw.isEmpty { domain = raw }
                if phase == 0 { phase = 1 }
                continue
            }

            // Option lines: A) B) C) D)
            if t.hasPrefix("A)") || t.hasPrefix("B)") || t.hasPrefix("C)") || t.hasPrefix("D)") {
                if phase < 2 { phase = 2 }
                let clean = t.replacingOccurrences(of: "**", with: "").trimmingCharacters(in: .whitespaces)
                if !clean.isEmpty { options.append(clean) }
                continue
            }

            // Correct answer line
            if t.hasPrefix("**Correct Answer") {
                if let r = t.range(of: ":") {
                    let raw = String(t[t.index(after: r.lowerBound)...])
                        .replacingOccurrences(of: "**", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    correctAnswer = normalizeAnswer(raw)
                }
                continue
            }

            // Explanation marker
            if t.hasPrefix("**Explanation") {
                phase = 3
                // Collect any text on the same line after the colon
                let rest = t.components(separatedBy: ":**").dropFirst().joined(separator: ":**")
                    .replacingOccurrences(of: "**", with: "").trimmingCharacters(in: .whitespaces)
                if !rest.isEmpty { explanationParts.append(rest) }
                continue
            }

            switch phase {
            case 0, 1:
                if phase == 0 { phase = 1 }
                questionParts.append(t)
            case 3:
                var clean = t.replacingOccurrences(of: "**", with: "").trimmingCharacters(in: .whitespaces)
                if clean.hasPrefix("- ") { clean = String(clean.dropFirst(2)) }
                if !clean.isEmpty { explanationParts.append(clean) }
            default:
                break
            }
        }

        let questionText = questionParts.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        guard !questionText.isEmpty, options.count >= 2, !correctAnswer.isEmpty else { return nil }

        return Question(
            questionText: questionText,
            options: options,
            correctAnswer: correctAnswer,
            explanation: explanationParts.joined(separator: " ").trimmingCharacters(in: .whitespaces),
            certType: certType,
            topic: domain
        )
    }

    private static func isStopMarker(_ t: String, phase: Int) -> Bool {
        // Only stop explanation collection; don't stop question collection
        guard phase >= 2 else { return false }
        return t.hasPrefix("**Why")
            || (t.hasPrefix("Why ") && (t.contains("incorrect") || t.contains("wrong")))
            || t.hasPrefix("**Incorrect")
            || t.hasPrefix("Incorrect A")
            || t.hasPrefix("These questions")
            || t.hasPrefix("### Multi")
    }

    // MARK: - Answer normalisation

    // Converts "A and C", "A, B, and C", "B and D" → canonical "A and C" form
    private static func normalizeAnswer(_ raw: String) -> String {
        let letters = raw
            .components(separatedBy: ",")
            .flatMap { $0.components(separatedBy: " and ") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { s in s.count == 1 && ["A", "B", "C", "D"].contains(s) }
        return letters.joined(separator: " and ")
    }

    // MARK: - Deduplication

    private static func deduplicate(_ questions: [Question]) -> [Question] {
        var seen = Set<String>()
        return questions.filter { q in
            let key = String(q.questionText.lowercased().prefix(80))
                .trimmingCharacters(in: .whitespaces)
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }
}
