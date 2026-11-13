import Foundation
import Combine

final class AppModel: ObservableObject {
    struct Banner: Identifiable {
        let id = UUID()
        let text: String
        let isError: Bool
    }

    @Published var projects: [Project] = []
    @Published var selectedProject: Project?
    @Published var files: [ScriptFile] = []
    @Published var openPaths: [String] = []
    @Published var activePath: String?
    @Published var banner: Banner?
    @Published var showingSettings = false
    @Published var showingAssistant = false
    @Published var showingImporter = false
    @Published var showingExporter = false
    @Published var exportDocument: ProjectDocument?
    @Published var exportFilename = "project.pythonst3"

    let store = ProjectStore()
    let runtime = PythonRuntime.shared

    private var saveWorkItem: DispatchWorkItem?

    init() {
        reloadProjects()
        if ProcessInfo.processInfo.arguments.contains("--pythonst3-demo") {
            openDemoProjectIfNeeded()
        }
    }

    private func openDemoProjectIfNeeded() {
        if let existing = projects.first(where: { $0.name == "Demo Project" }) {
            open(existing)
            return
        }
        do {
            let project = try store.createProject(name: "Demo Project")
            reloadProjects()
            open(project)
        } catch {
            show(error)
        }
    }

    var activeFile: ScriptFile? {
        files.first { $0.path == activePath }
    }

    var activeContent: String {
        activeFile?.content ?? ""
    }

    func reloadProjects() {
        projects = store.loadProjects()
    }

    func open(_ project: Project) {
        do {
            let loaded = try store.loadFiles(for: project)
            files = loaded
            openPaths = loaded.map { $0.path }
            activePath = loaded.first(where: { $0.path == project.entrypoint })?.path ?? loaded.first?.path
            selectedProject = project
            runtime.prepare()
        } catch {
            show(error)
        }
    }

    func closeProject() {
        saveActiveNow()
        selectedProject = nil
        files = []
        openPaths = []
        activePath = nil
        reloadProjects()
    }

    func createProject(named name: String) {
        do {
            let project = try store.createProject(name: name)
            reloadProjects()
            open(project)
        } catch {
            show(error)
        }
    }

    func updateActiveContent(_ content: String) {
        guard let index = files.firstIndex(where: { $0.path == activePath }) else { return }
        if files[index].content == content { return }
        files[index].content = content
        scheduleSave()
    }

    func saveActiveNow() {
        saveWorkItem?.cancel()
        guard let project = selectedProject, let file = activeFile else { return }
        do {
            try store.save(file: file, in: project)
            let now = Date()
            if var current = selectedProject {
                current.updatedAt = now
                selectedProject = current
            }
            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                projects[index].updatedAt = now
            }
        } catch {
            show(error)
        }
    }

    func runActive() {
        guard let project = selectedProject, let file = activeFile else { return }
        saveActiveNow()
        let timeout = UserDefaults.standard.object(forKey: "runtime.timeout") as? Int ?? 30
        runtime.run(
            source: file.content,
            filename: file.path,
            projectURL: store.folderURL(for: project),
            timeout: timeout
        )
    }

    func stop() {
        runtime.stop()
    }

    func createFile(named name: String) {
        guard let project = selectedProject else { return }
        do {
            let created = try store.createFile(named: name, in: project)
            files = try store.loadFiles(for: project)
            if !openPaths.contains(created.path) {
                openPaths.append(created.path)
            }
            activePath = created.path
        } catch {
            show(error)
        }
    }

    func deleteFile(_ file: ScriptFile) {
        guard let project = selectedProject else { return }
        if file.path == project.entrypoint {
            showMessage("لا يمكن حذف ملف البداية. غيّر نقطة البداية أولاً.")
            return
        }
        do {
            try store.deleteFile(path: file.path, in: project)
            files = try store.loadFiles(for: project)
            openPaths.removeAll { $0 == file.path }
            if activePath == file.path {
                activePath = files.first?.path
            }
        } catch {
            show(error)
        }
    }

    func deleteProject(_ project: Project) {
        do {
            try store.deleteProject(project)
            if selectedProject?.id == project.id {
                selectedProject = nil
                files = []
                openPaths = []
                activePath = nil
            }
            reloadProjects()
            showMessage("تم حذف المشروع.")
        } catch {
            show(error)
        }
    }

    func selectFile(_ path: String) {
        if !openPaths.contains(path) {
            openPaths.append(path)
        }
        activePath = path
    }

    func closeTab(_ path: String) {
        guard let index = openPaths.firstIndex(of: path) else { return }
        openPaths.remove(at: index)
        if activePath == path {
            if openPaths.isEmpty {
                activePath = nil
            } else {
                activePath = openPaths[min(index, openPaths.count - 1)]
            }
        }
    }

    func prepareExport(_ project: Project) {
        do {
            let data = try store.archive(for: project)
            exportDocument = ProjectDocument(data: data)
            let base = project.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let safe = base
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
            exportFilename = (safe.isEmpty ? "project" : safe) + ".pythonst3"
            showingExporter = true
        } catch {
            show(error)
        }
    }

    func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            showMessage("تم تصدير المشروع بنجاح.")
        case .failure(let error):
            show(error)
        }
        exportDocument = nil
    }

    func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            do {
                let project: Project
                if url.pathExtension.lowercased() == "py" {
                    project = try store.importPythonFile(url)
                } else {
                    let data = try Data(contentsOf: url)
                    project = try store.importArchive(data)
                }
                reloadProjects()
                open(project)
            } catch {
                show(error)
            }
        case .failure(let error):
            show(error)
        }
    }

    func showMessage(_ text: String) {
        banner = Banner(text: text, isError: false)
    }

    private func scheduleSave() {
        saveWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.saveActiveNow()
        }
        saveWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: item)
    }

    private func show(_ error: Error) {
        banner = Banner(text: error.localizedDescription, isError: true)
    }
}
