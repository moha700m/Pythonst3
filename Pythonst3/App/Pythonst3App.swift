import SwiftUI

@main
struct Pythonst3App: App {
    @StateObject private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .environment(\.layoutDirection, .rightToLeft)
                .preferredColorScheme(.dark)
                .tint(CyberTheme.neonGreen)
        }
    }
}
