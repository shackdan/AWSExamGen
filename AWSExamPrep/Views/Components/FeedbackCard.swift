import SwiftUI

struct FeedbackCard: View {
    let isCorrect:     Bool
    let correctAnswer: String
    let explanation:   String
    var referenceURL:  String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect
                      ? "checkmark.circle.fill"
                      : "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isCorrect ? .green : .red)

                Text(isCorrect
                     ? "Correct!"
                     : "Incorrect — correct answer is \(correctAnswer)")
                    .font(.subheadline.bold())
                    .foregroundStyle(isCorrect ? .green : .red)
            }

            Divider()

            Text(linkedExplanation)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            if let urlString = referenceURL, let url = URL(string: urlString) {
                Link(destination: url) {
                    Label("Learn more on AWS Docs", systemImage: "arrow.up.right.square")
                        .font(.caption.bold())
                }
                .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(
            (isCorrect ? Color.green : Color.red).opacity(0.08)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    (isCorrect ? Color.green : Color.red).opacity(0.3),
                    lineWidth: 1.5
                )
        )
    }

    // Builds an AttributedString with URLs auto-detected and made tappable.
    private var linkedExplanation: AttributedString {
        var attributed = AttributedString(explanation)
        attributed.foregroundColor = .secondary

        let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        )
        let matches = detector?.matches(
            in: explanation,
            range: NSRange(explanation.startIndex..., in: explanation)
        ) ?? []

        for match in matches {
            guard let url = match.url,
                  let range = Range(match.range, in: explanation),
                  let attrRange = Range(range, in: attributed) else { continue }
            attributed[attrRange].link = url
            attributed[attrRange].foregroundColor = .blue
        }
        return attributed
    }
}
