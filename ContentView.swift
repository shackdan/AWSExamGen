import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
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
                .tabItem { Label("Quiz",     systemImage: "list.bullet.clipboard.fill") }
                .tag(2)

            QuestionBankView()
                .tabItem { Label("Bank",     systemImage: "archivebox.fill") }
                .tag(3)
        }
        .tint(.orange)
        .onAppear {
            QuestionBankService.shared.seedIfNeeded(context: context)
        }
    }
}
