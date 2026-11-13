import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ProjectListView: View {
    @EnvironmentObject private var app: AppModel
    @ObservedObject private var runtime = PythonRuntime.shared
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var showingNewProject = false
    @State private var projectToDelete: Project?
    @State private var showingDelete = false

    private var horizontalPadding: CGFloat {
        sizeClass == .regular ? 26 : 16
    }

    private var contentMaxWidth: CGFloat {
        sizeClass == .regular ? 1100 : .infinity
    }

    private var columns: [GridItem] {
        if sizeClass == .regular {
            return [GridItem(.adaptive(minimum: 320), spacing: 14)]
        }
        return [GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        ZStack {
            CyberBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    hero
                    codeEntryCard
                    statusLine

                    HStack(alignment: .firstTextBaseline) {
                        SectionLabel(text: "PROJECTS / المشاريع")
                        Spacer(minLength: 8)
                        Text("\(app.projects.count)")
                            .font(CyberTheme.mono(11, weight: .semibold))
                            .foregroundStyle(CyberTheme.neonGreen)
                    }

                    if app.projects.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(app.projects) { project in
                                ProjectCard(
                                    project: project,
                                    onOpen: { app.open(project) },
                                    onExport: { app.prepareExport(project) },
                                    onDelete: {
                                        projectToDelete = project
                                        showingDelete = true
                                    }
                                )
                            }
                        }
                    }

                    footer
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 14)
                .padding(.bottom, 28)
                .frame(maxWidth: contentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .top, spacing: 0) { topBar }
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        }
        .background(CyberTheme.background)
        .fileImporter(
            isPresented: $app.showingImporter,
            allowedContentTypes: [.pythonst3, .json, .plainText],
            allowsMultipleSelection: false
        ) { result in
            app.handleImport(result)
        }
        .fileExporter(
            isPresented: $app.showingExporter,
            document: app.exportDocument,
            contentType: .pythonst3,
            defaultFilename: app.exportFilename
        ) { result in
            app.handleExportResult(result)
        }
        .sheet(isPresented: $showingNewProject) {
            NewProjectSheet()
        }
        .alert("حذف المشروع", isPresented: $showingDelete) {
            Button("حذف", role: .destructive) {
                if let project = projectToDelete {
                    app.deleteProject(project)
                }
                projectToDelete = nil
            }
            Button("إلغاء", role: .cancel) {
                projectToDelete = nil
            }
        } message: {
            Text("سيتم حذف «\(projectToDelete?.name ?? "")» وكل ملفاته نهائياً.")
        }
    }

    private var topBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 1) {
                Text("PYTHON")
                    .foregroundStyle(CyberTheme.neonGreen)
                Text("ST3")
                    .foregroundStyle(CyberTheme.neonCyan)
            }
            .font(.system(size: 18, weight: .black, design: .monospaced))
            .tracking(0.5)
            .accessibilityLabel("Pythonst3")

            Spacer(minLength: 8)

            IconActionButton(systemName: "sparkles", tint: CyberTheme.neonCyan) {
                app.showingAssistant = true
            }
            .accessibilityLabel("المساعد الذكي")

            IconActionButton(systemName: "gearshape", tint: CyberTheme.textSecondary) {
                app.showingSettings = true
            }
            .accessibilityLabel("الإعدادات")
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(
            CyberTheme.background
                .opacity(0.96)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(CyberTheme.neonGreen.opacity(0.12))
                        .frame(height: 0.5)
                }
        )
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text("PYTHONST3")
                    .font(.system(size: 29, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [CyberTheme.neonGreen, CyberTheme.neonCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("_")
                    .font(.system(size: 27, weight: .black, design: .monospaced))
                    .foregroundStyle(CyberTheme.neonMagenta)
            }

            Text("CODE BEYOND LIMITS")
                .font(CyberTheme.mono(9, weight: .semibold))
                .tracking(3.2)
                .foregroundStyle(CyberTheme.neonCyan.opacity(0.85))

            Text("محرر Python ومفسّر CPython مدمج — كل شيء محلي على جهازك.")
                .font(CyberTheme.arabic(13))
                .foregroundStyle(CyberTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The single most important control in the app: one tap and the caret is in a
    /// Python file. Pasting a whole program is the other one-tap path.
    private var codeEntryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(CyberTheme.neonCyan.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(CyberTheme.neonCyan)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("محرر الكود")
                        .font(CyberTheme.arabic(15, weight: .bold))
                        .foregroundStyle(CyberTheme.textPrimary)
                    Text("هنا تكتب أو تلصق كود Python مباشرة على الجهاز.")
                        .font(CyberTheme.arabic(11))
                        .foregroundStyle(CyberTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                Button {
                    app.startCoding()
                } label: {
                    Label("افتح المحرر", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CyberButtonStyle(filled: true))

                Button {
                    app.startProjectFromClipboard()
                } label: {
                    Label("لصق كود", systemImage: "doc.on.clipboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CyberButtonStyle(tint: CyberTheme.neonCyan))
            }
        }
        .padding(13)
        .neonPanel(accent: CyberTheme.neonCyan, cornerRadius: 16)
    }

    private var statusLine: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                StatusPill(text: "\(app.projects.count) مشروع", color: CyberTheme.neonGreen)
                StatusPill(text: runtime.state.label, color: stateColor)
                Spacer(minLength: 0)
            }
            Text("Python \(runtime.pythonVersion)  ·  iOS \(UIDevice.current.systemVersion)")
                .font(CyberTheme.mono(9, weight: .medium))
                .foregroundStyle(CyberTheme.textMuted)
                .lineLimit(1)
        }
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

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(CyberTheme.neonGreen.opacity(0.85))
            Text("لا توجد مشاريع بعد")
                .font(CyberTheme.arabic(17, weight: .semibold))
                .foregroundStyle(CyberTheme.textPrimary)
            Text("أنشئ مشروعك الأول وابدأ بكتابة Python على iPhone.")
                .font(CyberTheme.arabic(13))
                .foregroundStyle(CyberTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                app.startCoding()
            } label: {
                Label("ابدأ الكتابة الآن", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CyberButtonStyle(filled: true))
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 26)
        .neonPanel(cornerRadius: 16)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 5) {
            Divider().overlay(CyberTheme.neonGreen.opacity(0.12))
            Text("التنفيذ محلي داخل sandbox التطبيق. لا تُرفع الملفات تلقائياً إلى أي خدمة سحابية.")
                .font(CyberTheme.arabic(10))
                .foregroundStyle(CyberTheme.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4)
    }

    private var bottomBar: some View {
        HStack(spacing: 10) {
            Button {
                showingNewProject = true
            } label: {
                Label("مشروع جديد", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CyberButtonStyle(filled: true))

            Button {
                app.showingImporter = true
            } label: {
                Label("استيراد", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CyberButtonStyle(tint: CyberTheme.neonCyan))
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            LinearGradient(
                colors: [CyberTheme.background.opacity(0.0), CyberTheme.background.opacity(0.97), CyberTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct IconActionButton: View {
    let systemName: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(Circle().fill(CyberTheme.surface.opacity(0.9)))
                .overlay(Circle().stroke(tint.opacity(0.22), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
    }
}

struct ProjectCard: View {
    let project: Project
    let onOpen: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 11) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(CyberTheme.neonGreen.opacity(0.10))
                            .frame(width: 40, height: 40)
                        Image(systemName: "folder.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(CyberTheme.neonGreen)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(project.name)
                            .font(CyberTheme.arabic(16, weight: .semibold))
                            .foregroundStyle(CyberTheme.textPrimary)
                            .lineLimit(1)
                        Text(project.entrypoint)
                            .font(CyberTheme.mono(10))
                            .foregroundStyle(CyberTheme.textSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CyberTheme.neonCyan.opacity(0.75))
                }

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))
                    Text(project.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(CyberTheme.mono(9))
                    Spacer(minLength: 8)
                    Text("OPEN")
                        .font(CyberTheme.mono(8, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(CyberTheme.neonGreen)
                }
                .foregroundStyle(CyberTheme.textMuted)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .neonPanel(accent: CyberTheme.neonGreen, cornerRadius: 14)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onOpen()
            } label: {
                Label("فتح", systemImage: "arrow.left.square")
            }
            Button {
                onExport()
            } label: {
                Label("تصدير", systemImage: "square.and.arrow.up")
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("حذف", systemImage: "trash")
            }
        }
    }
}
