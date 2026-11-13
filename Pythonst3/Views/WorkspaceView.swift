import SwiftUI
import UIKit
import Combine

struct WorkspaceView: View {
    @EnvironmentObject private var app: AppModel
    @ObservedObject private var runtime = PythonRuntime.shared

    @AppStorage("editor.fontSize") private var editorFontSize: Double = 14

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
                fileTabs
                editorArea
                statusBar
                ConsoleView(
                    runtime: runtime,
                    expanded: $consoleExpanded,
                    height: consoleHeight(for: proxy.size.height)
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(CyberTheme.background.ignoresSafeArea())
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
        }
        .background(CyberTheme.background.ignoresSafeArea())
        .onAppear {
            runtime.prepare()
        }
        .onDisappear {
            app.saveActiveNow()
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
        guard consoleExpanded else { return 60 }
        return min(max(availableHeight * 0.34, 200), availableHeight * 0.52)
    }

    private var topBar: some View {
        HStack(spacing: 6) {
            Button {
                app.closeProject()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(CyberTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(CyberTheme.surface.opacity(0.9)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("العودة إلى المشاريع")

            VStack(alignment: .leading, spacing: 1) {
                Text(app.selectedProject?.name ?? "Pythonst3")
                    .font(CyberTheme.arabic(15, weight: .semibold))
                    .foregroundStyle(CyberTheme.textPrimary)
                    .lineLimit(1)
                Text(app.activeFile?.path ?? "—")
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
                Image(systemName: runtime.state == .running ? "stop.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(runtime.state == .running ? CyberTheme.danger : CyberTheme.neonGreen)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(
                            (runtime.state == .running ? CyberTheme.danger : CyberTheme.neonGreen).opacity(0.12)
                        )
                    )
                    .overlay(
                        Circle().stroke(
                            (runtime.state == .running ? CyberTheme.danger : CyberTheme.neonGreen).opacity(0.45),
                            lineWidth: 1
                        )
                    )
            }
            .buttonStyle(.plain)
            .disabled(app.activeFile == nil || runtime.state == .preparing)
            .opacity(app.activeFile == nil || runtime.state == .preparing ? 0.4 : 1)
            .accessibilityLabel(runtime.state == .running ? "إيقاف" : "تشغيل")

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    consoleExpanded.toggle()
                }
            } label: {
                Image(systemName: consoleExpanded ? "rectangle.compress.vertical" : "terminal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(consoleExpanded ? CyberTheme.neonCyan : CyberTheme.textSecondary)
                    .frame(width: 44, height: 44)
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
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("المزيد")
        }
        .padding(.horizontal, 10)
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
                    }
                )
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(CyberTheme.neonGreen.opacity(0.75))
                    Text("لا يوجد ملف مفتوح")
                        .font(CyberTheme.arabic(15, weight: .semibold))
                        .foregroundStyle(CyberTheme.textPrimary)
                    Button("إنشاء ملف") {
                        showNewFile = true
                    }
                    .buttonStyle(CyberButtonStyle(filled: true))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CyberTheme.background)
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
