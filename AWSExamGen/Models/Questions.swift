//
//  Questions.swift
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

nonisolated struct Question: Identifiable, Sendable {
    let id: UUID
    let questionText: String
    let options: [String]
    let correctAnswer: String
    let explanation: String
    let certType: String
    let topic: String
    let referenceURL: String?

    init(
        id: UUID = UUID(),
        questionText: String,
        options: [String],
        correctAnswer: String,
        explanation: String,
        certType: String = "SAA-C03",
        topic: String = "General",
        referenceURL: String? = nil
    ) {
        self.id = id
        self.questionText = questionText
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.certType = certType
        self.topic = topic
        self.referenceURL = referenceURL
    }

    func isCorrectOption(_ optionLetter: String) -> Bool {
        correctAnswerLetters.contains(optionLetter)
    }

    var isMultiSelect: Bool { correctAnswer.contains(" and ") }

    var correctAnswerLetters: Set<String> {
        Set(correctAnswer
            .components(separatedBy: " and ")
            .map { $0.trimmingCharacters(in: .whitespaces) })
    }

    // MARK: - Option parsing

    // Options are formatted like "A) text" or "A. text". Extracts just the leading letter.
    static func letter(fromOption option: String) -> String {
        guard let first = option.first, first.isLetter else { return "" }
        return String(first)
    }

    // Strips the leading "A) " / "A. " / "A: " marker (and any following whitespace) from an option.
    static func text(fromOption option: String) -> String {
        guard option.first?.isLetter == true else { return option }
        var rest = option.dropFirst()
        if let separator = rest.first, ").:-".contains(separator) {
            rest = rest.dropFirst()
        }
        while rest.first == " " {
            rest = rest.dropFirst()
        }
        return String(rest)
    }
}

// MARK: - Supporting types

struct QuizResult {
    let question: Question
    let userAnswers: [String]

    var isCorrect: Bool {
        Set(userAnswers) == question.correctAnswerLetters
    }

    var userAnswerDisplay: String {
        userAnswers.sorted().joined(separator: ", ")
    }
}
