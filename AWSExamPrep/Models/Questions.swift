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

struct Question: Identifiable {
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

let certTypes = [
    "SAA-C03", "DVA-C02", "SOA-C02",
    "SAP-C02", "DOP-C02", "CLF-C02",
    "ANS-C01", "MLS-C01", "MLA-C01",
    "AIF-C01", "DEA-C01", "SCS-C02", "PAS-C01"
]

let topics = [
    "General", "S3 and Storage", "EC2 and Compute",
    "VPC and Networking", "IAM and Security",
    "RDS and Databases", "Lambda and Serverless",
    "CloudFront and CDN", "EKS / ECS and Containers",
    "Route 53 and DNS", "CloudWatch and Monitoring",
    "SNS / SQS / EventBridge", "DynamoDB",
    "Elastic Load Balancing and Auto Scaling",
    "Cost Optimization", "High Availability and Disaster Recovery"
]
