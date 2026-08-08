import Foundation
import SwiftData

@Model
class Question: Identifiable, Codable {
    var id: UUID
    var questionText: String
    var options: [String]
    var correctAnswer: String
    var explanation: String
    var certType: String
    var topic: String
    var referenceURL: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        questionText: String,
        options: [String],
        correctAnswer: String,
        explanation: String,
        certType: String = "SAA-C03",
        topic: String = "General",
        referenceURL: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.questionText = questionText
        self.options = options
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.certType = certType
        self.topic = topic
        self.referenceURL = referenceURL
        self.createdAt = createdAt
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, questionText = "question", options,
             correctAnswer = "correct_answer",
             explanation, certType = "cert_type",
             topic, referenceURL = "reference_url", createdAt
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        questionText = try c.decode(String.self, forKey: .questionText)
        options      = try c.decode([String].self, forKey: .options)
        correctAnswer = try c.decode(String.self, forKey: .correctAnswer)
        explanation  = try c.decode(String.self, forKey: .explanation)
        certType     = try c.decodeIfPresent(String.self, forKey: .certType) ?? "SAA-C03"
        topic        = try c.decodeIfPresent(String.self, forKey: .topic) ?? "General"
        referenceURL = try c.decodeIfPresent(String.self, forKey: .referenceURL)
        createdAt    = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(questionText, forKey: .questionText)
        try c.encode(options, forKey: .options)
        try c.encode(correctAnswer, forKey: .correctAnswer)
        try c.encode(explanation, forKey: .explanation)
        try c.encode(certType, forKey: .certType)
        try c.encode(topic, forKey: .topic)
        try c.encodeIfPresent(referenceURL, forKey: .referenceURL)
        try c.encode(createdAt, forKey: .createdAt)
    }
}

// MARK: - Supporting types
struct QuizResult {
    let question: Question
    let userAnswer: String
    var isCorrect: Bool { userAnswer == question.correctAnswer }
}

struct GenerateConfig {
    var numQuestions: Int = 5
    var certType: String = "SAA-C03"
    var topic: String = "General"
    var saveToBank: Bool = true
}

let certTypes = [
    "SAA-C03", "DVA-C02", "SOA-C02",
    "SAP-C02", "DOP-C02", "CLF-C02",
    "ANS-C01", "MLS-C01"
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
