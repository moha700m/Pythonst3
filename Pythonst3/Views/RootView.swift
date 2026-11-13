import SwiftUI
import UIKit

struct RootView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.scenePhase) private var scenePhase

    private var showsLayoutProbe: Bool {
        ProcessInfo.processInfo.arguments.contains("--pythonst3-layout-probe")
            || ProcessInfo.processInfo.environment["PYTHONST3_LAYOUT_PROBE"] == "1"
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
        }
        .overlay {
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
        .sheet(isPresented: $app.showingAssistant, onDismiss: {
            app.discardPendingProposal()
        }) {
            AIAssistantView()
        }
        .onAppear {
            PythonRuntime.shared.prepare()
            writeProbeMarkerIfNeeded()
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                app.saveActiveNow()
            }
        }
    }

    /// Lets CI prove that probe mode really reached the app, not just the command line.
    private func writeProbeMarkerIfNeeded() {
        guard showsLayoutProbe else { return }
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        let screen = UIScreen.main.bounds
        let marker = "probe=active screen=\(Int(screen.width))x\(Int(screen.height)) scale=\(UIScreen.main.scale)\n"
        try? marker.write(
            to: directory.appendingPathComponent("layout_probe.txt"),
            atomically: true,
            encoding: .utf8
        )
    }
}

/// Debug-only overlay used by `Scripts/capture_layouts.sh`. It paints 8pt magenta
/// strips at the true screen edges so the CI pixel probe can prove the app window
/// covers the whole display instead of being letterboxed by an old SDK.
struct LayoutProbeOverlay: View {
    private let probe = Color(red: 1, green: 0, blue: 1)

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(probe)
                .frame(height: 8)
            Spacer(minLength: 0)
            Rectangle()
                .fill(probe)
                .frame(height: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
