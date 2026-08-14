//
//  ReviewCard.swift
//  AWSExamPrep
//
//  Copyright (c) 2026 Dan Newton
//  Licensed under CC BY-NC 4.0
//  https://creativecommons.org/licenses/by-nc/4.0/
//
//  You may share and adapt this code for non-commercial purposes only.
//  Attribution is required.
//
import SwiftUI

struct ReviewCard: View {
    let index:  Int
    let result: QuizResult
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { expanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    // Result indicator
                    ZStack {
                        Circle()
                            .fill(result.isCorrect ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: result.isCorrect
                              ? "checkmark" : "xmark")
                            .font(.caption.bold())
                            .foregroundStyle(result.isCorrect ? .green : .red)
                    }

                    Text("Q\(index)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    Text(result.question.questionText)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(expanded ? nil : 2)

                    Spacer()

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }

            // Expanded detail
            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider().padding(.horizontal)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(result.question.options, id: \.self) { opt in
                            let letter = String(opt.prefix(1))
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(optionColor(letter).opacity(0.15))
                                    .frame(width: 22, height: 22)
                                    .overlay(
                                        Text(letter)
                                            .font(.caption2.bold())
                                            .foregroundStyle(optionColor(letter))
                                    )
                                Text(String(opt.dropFirst(3)))
                                    .font(.caption)
                                    .foregroundStyle(optionColor(letter))
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Your answer vs correct
                    if !result.isCorrect {
                        HStack {
                            Label("Your answer: \(result.userAnswerDisplay)",
                                  systemImage: "xmark.circle")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                            Spacer()
                            Label("Correct: \(result.question.correctAnswer)",
                                  systemImage: "checkmark.circle")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal)
                    }

                    Text(result.question.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    if let urlString = result.question.referenceURL,
                       let url = URL(string: urlString) {
                        Link(destination: url) {
                            Label("Learn more on AWS Docs", systemImage: "arrow.up.right.square")
                                .font(.caption.bold())
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal)
                    }
                    Spacer().frame(height: 4)
                }
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private func optionColor(_ letter: String) -> Color {
        if result.question.isCorrectOption(letter) { return .green }
        if result.userAnswers.contains(letter)     { return .red   }
        return .secondary
    }
}
