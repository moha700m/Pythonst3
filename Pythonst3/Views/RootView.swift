import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.scenePhase) private var scenePhase

    private var showsLayoutProbe: Bool {
        ProcessInfo.processInfo.arguments.contains("--pythonst3-layout-probe")
    }

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

            if showsLayoutProbe {
                LayoutProbeOverlay()
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
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                app.saveActiveNow()
            }
        }
    }
}

/// Debug-only overlay used by `Scripts/capture_layouts.sh`. It paints 4pt magenta
/// strips at the true screen edges, so the CI pixel probe can prove the app window
/// covers the whole display instead of being letterboxed by an old SDK.
struct LayoutProbeOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(red: 1, green: 0, blue: 1))
                        .frame(height: 4)
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(Color(red: 1, green: 0, blue: 1))
                        .frame(height: 4)
                }

                Text("\(Int(proxy.size.width))×\(Int(proxy.size.height))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(red: 1, green: 0, blue: 1))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.top, 10)
                    .padding(.leading, 10)
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
