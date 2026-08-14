import SwiftUI

@main
struct AWSExamPrepApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
                .tag(0)

            QuizView()
                .tabItem { Label("Quiz", systemImage: "list.bullet.clipboard.fill") }
                .tag(1)

            QuestionBankView()
                .tabItem { Label("Bank", systemImage: "archivebox.fill") }
                .tag(2)
        }
        .tint(.orange)
    }
}

#Preview {
    ContentView()
}
