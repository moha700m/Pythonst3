import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        ZStack {
            CyberBackground()
            if app.selectedProject != nil {
                WorkspaceView()
                    .transition(.opacity)
            } else {
                ProjectListView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: app.selectedProject?.id)
        .alert(item: $app.banner) { banner in
            Alert(
                title: Text(banner.isError ? "خطأ" : "Pythonst3"),
                message: Text(banner.text),
                dismissButton: .default(Text("حسناً"))
            )
        }
        .sheet(isPresented: $app.showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $app.showingAssistant) {
            AIAssistantView()
        }
        .onAppear {
            PythonRuntime.shared.prepare()
        }
    }
}
