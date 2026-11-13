import SwiftUI
import UniformTypeIdentifiers

struct ProjectListView: View {
    @EnvironmentObject private var app: AppModel
    @ObservedObject private var runtime = PythonRuntime.shared

    @State private var newProjectName = ""
    @State private var showingNewProject = false
    @State private var projectToDelete: Project?
    @State private var showingDelete = false

    private let columns = [GridItem(.adaptive(minimum: 280), spacing: 16)]

    var body: some View {
        NavigationStack {
            ZStack {
                CyberBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        stats
                        actions
                        SectionLabel(text: "PROJECTS / المشاريع")
                        if app.projects.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: 1200)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        app.showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(CyberTheme.textSecondary)
                    }
                    .accessibilityLabel("الإعدادات")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        app.showingAssistant = true
                    } label: {
                        Image(systemName: "sparkles")
                            .foregroundStyle(CyberTheme.neonCyan)
                    }
                    .accessibilityLabel("المساعد الذكي")
                }
            }
            .toolbarBackground(CyberTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
            .alert("مشروع جديد", isPresented: $showingNewProject) {
                TextField("اسم المشروع", text: $newProjectName)
                Button("إنشاء") {
                    let name = newProjectName
                    newProjectName = ""
                    app.createProject(named: name)
                }
                Button("إلغاء", role: .cancel) {
                    newProjectName = ""
                }
            } message: {
                Text("سيُنشأ مشروع محلي داخل مساحة التطبيق، مع ملف main.py جاهز.")
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("PYTHONST3")
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [CyberTheme.neonGreen, CyberTheme.neonCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("_")
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .foregroundStyle(CyberTheme.neonMagenta)
                    .opacity(0.9)
            }
            Text("CODE BEYOND LIMITS")
                .font(CyberTheme.mono(11, weight: .semibold))
                .tracking(4)
                .foregroundStyle(CyberTheme.neonCyan.opacity(0.8))
            Text("بيئة Python عربية أصلية: محرر، مفسّر CPython مدمج، ومساعد برمجي — كل شيء محلي على جهازك.")
                .font(CyberTheme.arabic(15))
                .foregroundStyle(CyberTheme.textSecondary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stats: some View {
        HStack(spacing: 10) {
            StatusPill(text: "\(app.projects.count) مشروع", color: CyberTheme.neonGreen)
            StatusPill(text: runtime.state.label, color: stateColor)
            StatusPill(text: "Python \(runtime.pythonVersion)", color: CyberTheme.neonCyan)
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

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                showingNewProject = true
            } label: {
                Label("مشروع جديد", systemImage: "plus")
            }
            .buttonStyle(CyberButtonStyle(filled: true))

            Button {
                app.showingImporter = true
            } label: {
                Label("استيراد مشروع", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(CyberButtonStyle(tint: CyberTheme.neonCyan))

            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(CyberTheme.neonGreen.opacity(0.8))
            Text("لا توجد مشاريع بعد")
                .font(CyberTheme.arabic(18, weight: .semibold))
                .foregroundStyle(CyberTheme.textPrimary)
            Text("أنشئ مشروعك الأول وابدأ بكتابة Python على iPhone أو iPad.")
                .font(CyberTheme.arabic(14))
                .foregroundStyle(CyberTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button("إنشاء مشروع") {
                showingNewProject = true
            }
            .buttonStyle(CyberButtonStyle(filled: true))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .neonPanel(cornerRadius: 18)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider().overlay(CyberTheme.neonGreen.opacity(0.15))
            Text("التنفيذ محلي داخل sandbox التطبيق. لا تُرفع الملفات تلقائياً إلى أي خدمة سحابية.")
                .font(CyberTheme.arabic(12))
                .foregroundStyle(CyberTheme.textMuted)
        }
        .padding(.top, 10)
    }
}

struct ProjectCard: View {
    let project: Project
    let onOpen: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(CyberTheme.neonGreen.opacity(0.10))
                            .frame(width: 42, height: 42)
                        Image(systemName: "folder.fill")
                            .foregroundStyle(CyberTheme.neonGreen)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(CyberTheme.arabic(17, weight: .semibold))
                            .foregroundStyle(CyberTheme.textPrimary)
                            .lineLimit(1)
                        Text(project.entrypoint)
                            .font(CyberTheme.mono(11))
                            .foregroundStyle(CyberTheme.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CyberTheme.neonCyan.opacity(0.7))
                }

                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(project.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(CyberTheme.mono(10))
                    Spacer()
                    Text("OPEN")
                        .font(CyberTheme.mono(9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(CyberTheme.neonGreen)
                }
                .foregroundStyle(CyberTheme.textMuted)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .neonPanel(accent: CyberTheme.neonGreen, cornerRadius: 16)
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
