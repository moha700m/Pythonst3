import SwiftUI
import UIKit
import Combine

struct WorkspaceView: View {
    @EnvironmentObject private var app: AppModel
    @ObservedObject private var runtime = PythonRuntime.shared

    @AppStorage("editor.fontSize") private var editorFontSize: Double = 14
    @AppStorage("editor.coachDismissed") private var coachDismissed = false

    @State private var consoleExpanded = false
    @State private var showFiles = false
    @State private var showNewFile = false
    @State private var newFileName = ""
    @State private var cursorLine = 1
    @State private var cursorColumn = 1

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                topBar
                if !coachDismissed && app.activeFile != nil {
                    coachStrip
                }
                fileTabs
                editorArea
                statusBar
                ConsoleView(
                    runtime: runtime,
                    expanded: $consoleExpanded,
                    height: consoleHeight(for: proxy.size.height),
                    projectURL: app.selectedProject.map { app.store.folderURL(for: $0) }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(CyberTheme.background.ignoresSafeArea())
        .onAppear {
            runtime.prepare()
        }
        .onDisappear {
            app.saveActiveNow()
        }
        .onChange(of: runtime.state) { newState in
            if newState == .running {
                withAnimation(.easeInOut(duration: 0.2)) {
                    consoleExpanded = true
                }
            }
        }
        .onChange(of: runtime.pendingInput?.id) { _ in
            if runtime.pendingInput != nil {
                withAnimation(.easeInOut(duration: 0.2)) {
                    consoleExpanded = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            if runtime.pendingInput == nil {
                withAnimation(.easeInOut(duration: 0.2)) {
                    consoleExpanded = false
                }
            }
        }
        .sheet(isPresented: $showFiles) {
            FileListView()
        }
        .alert("ملف جديد", isPresented: $showNewFile) {
            TextField("utils.py", text: $newFileName)
            Button("إنشاء") {
                let name = newFileName
                newFileName = ""
                app.createFile(named: name)
            }
            Button("إلغاء", role: .cancel) {
                newFileName = ""
            }
        } message: {
            Text("أضف ملف Python جديداً داخل المشروع الحالي.")
        }
    }

    private func consoleHeight(for availableHeight: CGFloat) -> CGFloat {
        guard consoleExpanded else { return 56 }
        return min(max(availableHeight * 0.32, 180), availableHeight * 0.50)
    }

    private var topBar: some View {
        HStack(spacing: 4) {
            Button {
                app.closeProject()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(CyberTheme.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(CyberTheme.surface.opacity(0.9)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("العودة إلى المشاريع")

            VStack(alignment: .leading, spacing: 1) {
                Text(app.selectedProject?.name ?? "Pythonst3")
                    .font(CyberTheme.arabic(14, weight: .semibold))
                    .foregroundStyle(CyberTheme.textPrimary)
                    .lineLimit(1)
                Text(app.activeFile?.path ?? "لا يوجد ملف")
                    .font(CyberTheme.mono(9))
                    .foregroundStyle(CyberTheme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            Button {
                if runtime.state == .running {
                    app.stop()
                } else if runtime.state == .stopping {
                    return
                } else {
                    app.runActive()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: runtime.state == .running ? "stop.fill" : "play.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(runtime.state == .running ? "إيقاف" : "تشغيل")
                        .font(CyberTheme.arabic(12, weight: .bold))
                }
                .foregroundStyle(runtime.state == .running ? CyberTheme.danger : CyberTheme.neonGreen)
                .padding(.horizontal, 11)
                .frame(height: 34)
                .background(
                    Capsule().fill(
                        (runtime.state == .running ? CyberTheme.danger : CyberTheme.neonGreen).opacity(0.14)
                    )
                )
                .overlay(
                    Capsule().stroke(
                        (runtime.state == .running ? CyberTheme.danger : CyberTheme.neonGreen).opacity(0.5),
                        lineWidth: 1
                    )
                )
            }
            .buttonStyle(.plain)
            .disabled(app.activeFile == nil || runtime.state == .preparing)
            .opacity(app.activeFile == nil || runtime.state == .preparing ? 0.4 : 1)
            .accessibilityLabel(runtime.state == .running ? "إيقاف التنفيذ" : "تشغيل الكود")

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    consoleExpanded.toggle()
                }
            } label: {
                Image(systemName: consoleExpanded ? "rectangle.compress.vertical" : "terminal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(consoleExpanded ? CyberTheme.neonCyan : CyberTheme.textSecondary)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(consoleExpanded ? "تصغير وحدة التحكم" : "توسيع وحدة التحكم")

            Menu {
                Button {
                    showFiles = true
                } label: {
                    Label("ملفات المشروع", systemImage: "folder")
                }
                Button {
                    showNewFile = true
                } label: {
                    Label("ملف جديد", systemImage: "doc.badge.plus")
                }
                Button {
                    _ = app.pasteClipboardIntoActiveFile()
                } label: {
                    Label("لصق من الحافظة", systemImage: "doc.on.clipboard")
                }
                Button {
                    app.undoAgentChange()
                } label: {
                    Label("تراجع عن تعديل الذكاء الاصطناعي", systemImage: "arrow.uturn.backward")
                }
                .disabled(app.agentUndo == nil)

                Button {
                    app.saveActiveNow()
                } label: {
                    Label("حفظ الآن", systemImage: "square.and.arrow.down")
                }
                Divider()
                Button {
                    app.showingAssistant = true
                } label: {
                    Label("المساعد الذكي", systemImage: "sparkles")
                }
                Button {
                    app.showingSettings = true
                } label: {
                    Label("الإعدادات", systemImage: "gearshape")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 17))
                    .foregroundStyle(CyberTheme.textSecondary)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("المزيد")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            CyberTheme.surface
                .opacity(0.94)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(CyberTheme.neonGreen.opacity(0.14))
                        .frame(height: 0.5)
                }
        )
    }

    /// Shown only until the first run. It answers the two questions a new user has:
    /// where does the code go, and how do I get code from the clipboard in.
    private var coachStrip: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 11))
                .foregroundStyle(CyberTheme.amber)

            VStack(alignment: .leading, spacing: 1) {
                Text("الكود يُكتب في المساحة السوداء بالأسفل")
                    .font(CyberTheme.arabic(11.5, weight: .semibold))
                    .foregroundStyle(CyberTheme.textPrimary)
                    .lineLimit(1)
                Text("الصق أي كود ثم اضغط «تشغيل» في الأعلى")
                    .font(CyberTheme.arabic(9.5))
                    .foregroundStyle(CyberTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Button {
                _ = app.pasteClipboardIntoActiveFile()
            } label: {
                Text("لصق")
                    .font(CyberTheme.arabic(11, weight: .bold))
                    .foregroundStyle(CyberTheme.amber)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(Capsule().fill(CyberTheme.amber.opacity(0.14)))
                    .overlay(Capsule().stroke(CyberTheme.amber.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("لصق الكود من الحافظة")

            Button {
                coachDismissed = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(CyberTheme.textMuted)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("إخفاء التلميح")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(CyberTheme.amber.opacity(0.06))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(CyberTheme.amber.opacity(0.18))
                .frame(height: 0.5)
        }
    }

    private var fileTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(app.openPaths, id: \.self) { path in
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 9))
                        Text((path as NSString).lastPathComponent)
                            .font(CyberTheme.mono(10, weight: .medium))
                            .lineLimit(1)
                        Button {
                            app.closeTab(path)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("إغلاق الملف")
                    }
                    .foregroundStyle(app.activePath == path ? CyberTheme.textPrimary : CyberTheme.textSecondary)
                    .padding(.leading, 9)
                    .padding(.trailing, 4)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                app.activePath == path
                                    ? CyberTheme.neonGreen.opacity(0.12)
                                    : CyberTheme.surface.opacity(0.55)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(
                                app.activePath == path ? CyberTheme.neonGreen.opacity(0.4) : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        app.selectFile(path)
                    }
                }

                Button {
                    showNewFile = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(CyberTheme.neonGreen)
                        .frame(width: 40, height: 36)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("ملف جديد")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
        }
        .background(CyberTheme.background.opacity(0.8))
    }

    private var editorArea: some View {
        Group {
            if app.activeFile != nil {
                CodeEditorView(
                    text: Binding(
                        get: { app.activeContent },
                        set: { app.updateActiveContent($0) }
                    ),
                    fontSize: CGFloat(editorFontSize),
                    onCursorChange: { line, column in
                        cursorLine = line
                        cursorColumn = column
                    },
                    onRun: { app.runActive() },
                    onMessage: { message in app.showMessage(message) }
                )
            } else {
                emptyEditor
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CyberTheme.background)
    }

    private var emptyEditor: some View {
        VStack(spacing: 12) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(CyberTheme.neonGreen.opacity(0.85))
            Text("لا يوجد ملف مفتوح")
                .font(CyberTheme.arabic(15, weight: .semibold))
                .foregroundStyle(CyberTheme.textPrimary)
            Text("أنشئ ملفاً أو ألصق كوداً جاهزاً من الحافظة.")
                .font(CyberTheme.arabic(12))
                .foregroundStyle(CyberTheme.textSecondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                Button("ملف جديد") {
                    showNewFile = true
                }
                .buttonStyle(CyberButtonStyle(filled: true))

                Button("لصق كود") {
                    app.createFileFromClipboard()
                }
                .buttonStyle(CyberButtonStyle(tint: CyberTheme.neonCyan))
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statusBar: some View {
        HStack(spacing: 10) {
            Text("Ln \(cursorLine), Col \(cursorColumn)")
            Text("UTF-8")
            Spacer(minLength: 4)
            Text(runtime.state.label)
                .foregroundStyle(stateColor)
            Text("CPYTHON")
                .foregroundStyle(CyberTheme.textMuted)
        }
        .font(CyberTheme.mono(8.5, weight: .medium))
        .foregroundStyle(CyberTheme.textMuted)
        .lineLimit(1)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(CyberTheme.surfaceElevated.opacity(0.6))
    }

    private var stateColor: Color {
        switch runtime.state {
        case .ready: return CyberTheme.neonGreen
        case .running: return CyberTheme.neonCyan
        case .preparing, .stopping: return CyberTheme.amber
        case .failed: return CyberTheme.danger
        case .idle: return CyberTheme.textMuted
        }
    }
}
