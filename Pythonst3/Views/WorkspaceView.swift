import SwiftUI

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
        VStack(spacing: 0) {
            topBar
            fileTabs
            Divider()
                .overlay(CyberTheme.neonGreen.opacity(0.15))
            editorArea
            statusBar
            ConsoleView(runtime: runtime, expanded: $consoleExpanded)
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

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                app.closeProject()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(CyberTheme.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(CyberTheme.surface))
            }
            .accessibilityLabel("العودة إلى المشاريع")

            VStack(alignment: .leading, spacing: 2) {
                Text(app.selectedProject?.name ?? "Pythonst3")
                    .font(CyberTheme.arabic(16, weight: .semibold))
                    .foregroundStyle(CyberTheme.textPrimary)
                    .lineLimit(1)
                Text(app.activeFile?.path ?? "—")
                    .font(CyberTheme.mono(10))
                    .foregroundStyle(CyberTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            StatusPill(text: runtime.state.label, color: stateColor)

            Button {
                app.runActive()
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(CyberTheme.neonGreen)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(CyberTheme.neonGreen.opacity(0.12)))
                    .overlay(Circle().stroke(CyberTheme.neonGreen.opacity(0.45), lineWidth: 1))
            }
            .disabled(runtime.state.isBusy || app.activeFile == nil)
            .opacity(runtime.state.isBusy || app.activeFile == nil ? 0.4 : 1)
            .accessibilityLabel("تشغيل")

            Button {
                app.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(CyberTheme.danger)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(CyberTheme.danger.opacity(0.10)))
                    .overlay(Circle().stroke(CyberTheme.danger.opacity(0.40), lineWidth: 1))
            }
            .disabled(runtime.state != .running)
            .opacity(runtime.state != .running ? 0.4 : 1)
            .accessibilityLabel("إيقاف")

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    consoleExpanded.toggle()
                }
            } label: {
                Image(systemName: "terminal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(consoleExpanded ? CyberTheme.neonCyan : CyberTheme.textSecondary)
                    .frame(width: 34, height: 34)
            }
            .accessibilityLabel("توسيع وحدة التحكم")

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
                    .frame(width: 34, height: 34)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CyberTheme.surface.opacity(0.82))
    }

    private var stateColor: Color {
        switch runtime.state {
        case .ready:
            return CyberTheme.neonGreen
        case .running:
            return CyberTheme.neonCyan
        case .preparing, .stopping:
            return CyberTheme.amber
        case .failed:
            return CyberTheme.danger
        case .idle:
            return CyberTheme.textMuted
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
                            .font(CyberTheme.mono(11, weight: .medium))
                            .lineLimit(1)
                        Button {
                            app.closeTab(path)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .padding(2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("إغلاق الملف")
                    }
                    .foregroundStyle(app.activePath == path ? CyberTheme.textPrimary : CyberTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(app.activePath == path ? CyberTheme.neonGreen.opacity(0.12) : CyberTheme.surface.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(
                                app.activePath == path ? CyberTheme.neonGreen.opacity(0.4) : Color.clear,
                                lineWidth: 1
                            )
                    )
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
                        .padding(8)
                }
                .accessibilityLabel("ملف جديد")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
        }
        .background(CyberTheme.background.opacity(0.7))
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
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(CyberTheme.neonGreen.opacity(0.7))
                    Text("لا يوجد ملف مفتوح")
                        .font(CyberTheme.arabic(16, weight: .semibold))
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
        HStack(spacing: 12) {
            Text("Ln \(cursorLine), Col \(cursorColumn)")
            Text("UTF-8")
            Text("Python")
            Spacer()
            if case .failed = runtime.state {
                Text("RUNTIME ERROR")
                    .foregroundStyle(CyberTheme.danger)
            } else {
                Text("CPYTHON EMBEDDED")
                    .foregroundStyle(CyberTheme.neonGreen.opacity(0.8))
            }
        }
        .font(CyberTheme.mono(9, weight: .medium))
        .foregroundStyle(CyberTheme.textMuted)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(CyberTheme.surfaceElevated.opacity(0.55))
    }
}
