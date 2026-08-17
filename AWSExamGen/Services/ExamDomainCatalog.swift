//
//  ExamDomainCatalog.swift
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

// Canonical "Content Domain" names per certification, as published in the official
// exam guides (kept in sync with docs/exam-domains.txt). Question-bank data files
// sometimes use slightly different wording for the same domain (e.g. AI-generated
// content drifting from the exam guide's exact phrasing), so this catalog is used
// to normalize whatever domain string is parsed out of a question file to the
// canonical name before it reaches the Quiz Settings domain picker.
nonisolated enum ExamDomainCatalog {

    static let domains: [String: [String]] = [
        "AIF-C01": [
            "Fundamentals of AI and ML",
            "Fundamentals of GenAI",
            "Applications of Foundation Models",
            "Guidelines for Responsible AI",
            "Security, Compliance, and Governance for AI Solutions"
        ],
        "CLF-C02": [
            "Cloud Concepts",
            "Security and Compliance",
            "Cloud Technology and Services",
            "Billing, Pricing, and Support"
        ],
        "SOA-C03": [
            "Monitoring, Logging, Analysis, Remediation, and Performance Optimization",
            "Reliability and Business Continuity",
            "Deployment, Provisioning, and Automation",
            "Security and Compliance",
            "Networking and Content Delivery"
        ],
        "DEA-C01": [
            "Data Ingestion and Transformation",
            "Data Store Management",
            "Data Operations and Support",
            "Data Security and Governance"
        ],
        "DVA-C02": [
            "Development with AWS Services",
            "Security",
            "Deployment",
            "Troubleshooting and Optimization"
        ],
        "MLA-C01": [
            "Data Preparation for Machine Learning (ML)",
            "ML Model Development",
            "Deployment and Orchestration of ML Workflows",
            "ML Solution Monitoring, Maintenance, and Security"
        ],
        "SAA-C03": [
            "Design Secure Architectures",
            "Design Resilient Architectures",
            "Design High-Performing Architectures",
            "Design Cost-Optimized Architectures"
        ],
        "DOP-C02": [
            "SDLC Automation",
            "Configuration Management and IaC",
            "Resilient Cloud Solutions",
            "Monitoring and Logging",
            "Incident and Event Response",
            "Security and Compliance"
        ],
        "AIP-C01": [
            "Foundation Model Integration, Data Management, and Compliance",
            "Implementation and Integration",
            "AI Safety, Security, and Governance",
            "Operational Efficiency and Optimization for GenAI Applications",
            "Testing, Validation, and Troubleshooting"
        ],
        "SAP-C02": [
            "Design Solutions for Organizational Complexity",
            "Design for New Solutions",
            "Continuous Improvement for Existing Solutions",
            "Accelerate Workload Migration and Modernization"
        ],
        "ANS-C01": [
            "Network Design",
            "Network Implementation",
            "Network Management and Operation",
            "Network Security, Compliance, and Governance"
        ],
        "SCS-C03": [
            "Detection",
            "Incident Response",
            "Infrastructure Security",
            "Identity and Access Management",
            "Data Protection",
            "Security Foundations and Governance"
        ]
    ]

    // Known wording drift between question-bank data and the exam guide's exact
    // domain names, keyed by cert type then by the normalized raw string.
    private static let aliases: [String: [String: String]] = [
        "AIF-C01": ["fundamentalsofgenerativeai": "Fundamentals of GenAI"],
        "ANS-C01": ["networkmanagementandoperations": "Network Management and Operation"],
        "MLA-C01": ["datapreparationformachinelearning": "Data Preparation for Machine Learning (ML)"]
    ]

    // Maps a raw domain string parsed from question-bank data to the canonical exam
    // guide wording for the given cert. Falls back to the raw string unchanged when
    // the cert isn't in the catalog, or no canonical domain matches (so the value
    // still renders in the picker rather than silently disappearing).
    static func canonicalDomain(_ raw: String, certType: String) -> String {
        guard let list = domains[certType] else { return raw }
        let normalizedRaw = normalize(raw)
        if let exact = list.first(where: { normalize($0) == normalizedRaw }) {
            return exact
        }
        if let aliased = aliases[certType]?[normalizedRaw] {
            return aliased
        }
        return raw
    }

    private static func normalize(_ s: String) -> String {
        s.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
