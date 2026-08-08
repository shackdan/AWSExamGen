import SwiftUI
import SwiftData

@main
struct AWSExamPrepApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Question.self)
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("openai_api_key") private var apiKey = ""
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
                .tag(0)

            GenerateView()
                .tabItem { Label("Generate", systemImage: "sparkles") }
                .tag(1)

            QuizView()
                .tabItem { Label("Quiz", systemImage: "list.bullet.clipboard.fill") }
                .tag(2)

            QuestionBankView()
                .tabItem { Label("Bank", systemImage: "archivebox.fill") }
                .tag(3)
        }
        .tint(.orange)
        .onAppear {
            QuestionBankService.shared.seedIfNeeded(context: context)
            applyAPIKey()
        }
    }

    /// Route generation to OpenAI when a key is stored and no local model is loaded.
    private func applyAPIKey() {
        let llm = LLMService.shared
        if llm.loadedModelName == nil, !apiKey.isEmpty {
            llm.backend = .openAI(key: apiKey)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Question.self, inMemory: true)
}
