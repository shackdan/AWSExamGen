import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var allQuestions: [Question]
    @State private var showSettings = false

    var certCounts: [(cert: String, count: Int)] {
        Dictionary(grouping: allQuestions, by: \.certType)
            .map { (cert: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Hero banner
                    VStack(spacing: 8) {
                        Text("☁️")
                            .font(.system(size: 56))
                        Text("AWS Exam Prep")
                            .font(.largeTitle.bold())
                        Text("AI-powered questions · On-device Neural Engine")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // Stats row
                    HStack(spacing: 12) {
                        StatCard(
                            value: "\(allQuestions.count)",
                            label: "Questions",
                            icon: "doc.text.fill",
                            color: .orange
                        )
                        StatCard(
                            value: "\(certCounts.count)",
                            label: "Cert Types",
                            icon: "rosette",
                            color: .blue
                        )
                        StatCard(
                            value: uniqueTopics,
                            label: "Topics",
                            icon: "tag.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)

                    // Model status card
                    ModelStatusCard()
                        .padding(.horizontal)

                    // Cert breakdown
                    if !certCounts.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Questions by Certification")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(certCounts, id: \.cert) { item in
                                CertBarRow(
                                    cert:  item.cert,
                                    count: item.count,
                                    total: allQuestions.count
                                )
                            }
                        }
                        .padding(.vertical)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }

                    // Quick action cards
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Get Started")
                            .font(.headline)

                        HStack(spacing: 12) {
                            NavigationLink {
                                GenerateView()
                            } label: {
                                QuickActionCard(
                                    icon: "sparkles",
                                    title: "Generate",
                                    subtitle: "Create new questions with AI",
                                    color: .orange
                                )
                            }
                            NavigationLink {
                                QuizView()
                            } label: {
                                QuickActionCard(
                                    icon: "list.bullet.clipboard.fill",
                                    title: "Quiz",
                                    subtitle: "Test your knowledge",
                                    color: .blue
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private var uniqueTopics: String {
        "\(Set(allQuestions.map(\.topic)).count)"
    }
}

// MARK: - Sub-components

struct StatCard: View {
    let value:  String
    let label:  String
    let icon:   String
    let color:  Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct CertBarRow: View {
    let cert:  String
    let count: Int
    let total: Int

    var fraction: Double { total > 0 ? Double(count) / Double(total) : 0 }

    var body: some View {
        HStack(spacing: 12) {
            Text(cert)
                .font(.subheadline.bold())
                .frame(width: 90, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.orange.opacity(0.15))
                    Capsule()
                        .fill(Color.orange)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 10)
            Text("\(count)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
        }
        .padding(.horizontal)
    }
}

struct QuickActionCard: View {
    let icon:     String
    let title:    String
    let subtitle: String
    let color:    Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .padding(10)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ModelStatusCard: View {
    private let llm = LLMService.shared

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: llm.loadedModelName != nil
                  ? "brain.head.profile"
                  : "cloud.fill")
                .font(.title2)
                .foregroundStyle(llm.loadedModelName != nil ? .purple : .blue)
                .padding(10)
                .background(
                    (llm.loadedModelName != nil ? Color.purple : Color.blue).opacity(0.12)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(llm.loadedModelName ?? "OpenAI GPT-4o-mini")
                    .font(.subheadline.bold())
                Text(llm.loadedModelName != nil
                     ? "On-device · Neural Engine · Private"
                     : "Cloud API · Requires internet & API key")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Circle()
                .fill(llm.loadedModelName != nil ? Color.green : Color.blue)
                .frame(width: 10, height: 10)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
