import SwiftUI

enum OptionState {
    case unanswered, correct, incorrect
}

struct OptionButton: View {
    let option:   String
    let letter:   String
    let state:    OptionState
    let disabled: Bool
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Letter badge
                ZStack {
                    Circle()
                        .fill(badgeBackground)
                        .frame(width: 36, height: 36)
                    Text(letter)
                        .font(.subheadline.bold())
                        .foregroundStyle(badgeForeground)
                }

                Text(String(option.dropFirst(3)))   // strip "A) "
                    .font(.subheadline)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // State icon
                if state != .unanswered {
                    Image(systemName: state == .correct
                          ? "checkmark.circle.fill"
                          : "xmark.circle.fill")
                        .foregroundStyle(state == .correct ? .green : .red)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .disabled(disabled)
        .animation(.easeInOut(duration: 0.2), value: state)
    }

    // MARK: - Appearance helpers
    private var rowBackground: Color {
        switch state {
        case .unanswered: return Color(.secondarySystemBackground)
        case .correct:    return .green.opacity(0.1)
        case .incorrect:  return .red.opacity(0.1)
        }
    }

    private var borderColor: Color {
        switch state {
        case .unanswered: return .clear
        case .correct:    return .green
        case .incorrect:  return .red
        }
    }

    private var badgeBackground: Color {
        switch state {
        case .unanswered: return .orange.opacity(0.15)
        case .correct:    return .green
        case .incorrect:  return .red
        }
    }

    private var badgeForeground: Color {
        switch state {
        case .unanswered: return .orange
        case .correct, .incorrect: return .white
        }
    }

    private var textColor: Color {
        switch state {
        case .unanswered: return .primary
        case .correct:    return .green
        case .incorrect:  return .red
        }
    }
}
