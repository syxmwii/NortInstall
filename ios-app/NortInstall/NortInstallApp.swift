import SwiftUI

@main
struct NortInstallApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasSeenOnboarding {
                    RootView()
                        .transition(.opacity)
                } else {
                    OnboardingView {
                        withAnimation(Theme.spring) { hasSeenOnboarding = true }
                    }
                    .transition(.opacity)
                }
            }
            .environmentObject(appState)
            .tint(Theme.accent)
            .preferredColorScheme(.dark)
            .onOpenURL { appState.handle(url: $0) }
        }
    }
}
