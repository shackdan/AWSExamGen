//
//  QuestionBankService.swift
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

@Observable
final class QuestionBankService {

    static let shared = QuestionBankService()

    let allQuestions: [Question]

    private init() {
        allQuestions = Self.loadFromBundle()
    }

    // MARK: - Filtered access

    var availableCerts: [String] {
        Array(Set(allQuestions.map(\.certType))).sorted()
    }

    var availableTopics: [String] {
        Array(Set(allQuestions.map(\.topic))).sorted()
    }

    func questions(certType: String? = nil, topic: String? = nil) -> [Question] {
        allQuestions.filter { q in
            (certType == nil || q.certType == certType!) &&
            (topic    == nil || q.topic    == topic!)
        }
    }

    // MARK: - Bundle loading

    private static func loadFromBundle() -> [Question] {
        var urls: [URL] = []
        for ext in ["json", "md"] {
            urls += Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
            urls += Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "question_bank") ?? []
        }

        var seenFilenames = Set<String>()
        let uniqueURLs = urls.filter { seenFilenames.insert($0.lastPathComponent).inserted }

        var all: [Question] = []
        for url in uniqueURLs {
            let parsed = url.pathExtension == "json"
                ? MarkdownQuestionParser.parseJSON(fileURL: url)
                : MarkdownQuestionParser.parse(fileURL: url)
            if !parsed.isEmpty {
                print("QuestionBankService: loaded \(parsed.count) from \(url.lastPathComponent)")
                all.append(contentsOf: parsed)
            }
        }

        // Deduplicate across files by question text prefix
        var seenTexts = Set<String>()
        let unique = all.filter { q in
            seenTexts.insert(String(q.questionText.lowercased().prefix(80))).inserted
        }
        print("QuestionBankService: \(unique.count) unique questions loaded ✅")
        return unique
    }
}
