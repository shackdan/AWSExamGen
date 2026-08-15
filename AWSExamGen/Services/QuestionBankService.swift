//
//  QuestionBankService.swift
//  AWSExamGen
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

    private(set) var allQuestions: [Question] = []
    private(set) var isLoading = true
    private(set) var importedFilenames: [String] = []

    private init() {
        reload()
    }

    // MARK: - Importing

    enum ImportError: LocalizedError {
        case accessDenied
        case noQuestionsFound

        var errorDescription: String? {
            switch self {
            case .accessDenied: return "Couldn't access the selected file."
            case .noQuestionsFound: return "No valid questions were found in that file."
            }
        }
    }

    // Copies a user-picked JSON file into app storage, validates it parses into
    // at least one question, then reloads the bank. Rejects/removes it otherwise
    // so a bad file can't silently sit in the imported folder.
    @discardableResult
    func importFile(from sourceURL: URL) throws -> Int {
        guard sourceURL.startAccessingSecurityScopedResource() else {
            throw ImportError.accessDenied
        }
        defer { sourceURL.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: sourceURL)
        let destURL = Self.importedDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        try data.write(to: destURL, options: .atomic)

        let parsed = MarkdownQuestionParser.parseJSON(fileURL: destURL)
        guard !parsed.isEmpty else {
            try? FileManager.default.removeItem(at: destURL)
            throw ImportError.noQuestionsFound
        }

        reload()
        return parsed.count
    }

    func removeImportedFile(_ filename: String) {
        try? FileManager.default.removeItem(at: Self.importedDirectory.appendingPathComponent(filename))
        reload()
    }

    private func reload() {
        isLoading = true
        Task.detached(priority: .userInitiated) {
            let bundled = Self.loadFromBundle()
            let imported = Self.loadFromImportedDirectory()
            let merged = Self.deduplicate(bundled + imported)
            let filenames = Self.listImportedFilenames()
            await MainActor.run { [weak self] in
                self?.allQuestions = merged
                self?.importedFilenames = filenames
                self?.isLoading = false
            }
        }
    }

    // MARK: - Imported file storage

    private static var importedDirectory: URL {
        let dir = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImportedQuestionBanks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func listImportedFilenames() -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: importedDirectory.path))?.sorted() ?? []
    }

    private static func loadFromImportedDirectory() -> [Question] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: importedDirectory, includingPropertiesForKeys: nil)) ?? []
        return urls
            .filter { $0.pathExtension == "json" }
            .flatMap { MarkdownQuestionParser.parseJSON(fileURL: $0) }
    }

    private static func deduplicate(_ questions: [Question]) -> [Question] {
        var seenTexts = Set<String>()
        return questions.filter { q in
            seenTexts.insert(Self.dedupeKey(certType: q.certType, questionText: q.questionText)).inserted
        }
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

    nonisolated private static func loadFromBundle() -> [Question] {
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

        // Deduplicate across files, scoped per cert so distinct certs never collide
        var seenTexts = Set<String>()
        let unique = all.filter { q in
            seenTexts.insert(Self.dedupeKey(certType: q.certType, questionText: q.questionText)).inserted
        }
        print("QuestionBankService: \(unique.count) unique questions loaded ✅")
        return unique
    }

    // Scoped by certType so two different certs never collapse into one
    // just because their question text happens to start the same way.
    nonisolated static func dedupeKey(certType: String, questionText: String) -> String {
        let normalized = questionText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return "\(certType)|\(normalized)"
    }
}
