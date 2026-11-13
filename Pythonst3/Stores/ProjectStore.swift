import Foundation

enum ProjectStoreError: LocalizedError {
    case invalidName
    case invalidPath
    case alreadyExists
    case notFound
    case unreadable
    case tooLarge

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "اسم المشروع أو الملف غير صالح."
        case .invalidPath:
            return "مسار الملف غير آمن أو غير مسموح."
        case .alreadyExists:
            return "يوجد ملف بهذا الاسم بالفعل."
        case .notFound:
            return "لم يتم العثور على المشروع أو الملف."
        case .unreadable:
            return "تعذر قراءة ملف المشروع. تأكد من أنه أرشيف Pythonst3 صالح."
        case .tooLarge:
            return "حجم المشروع أكبر من الحد المسموح."
        }
    }
}

func isSafeRelativePath(_ path: String) -> Bool {
    let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, trimmed.count <= 180 else { return false }
    guard !trimmed.hasPrefix("/"), !trimmed.hasPrefix("~") else { return false }
    for component in trimmed.split(separator: "/", omittingEmptySubsequences: false) {
        if component.isEmpty || component == "." || component == ".." { return false }
        if component.contains("\\") { return false }
        if component.hasPrefix(".") { return false }
    }
    return true
}

final class ProjectStore {
    let rootURL: URL
    let projectsURL: URL

    private let fileManager = FileManager.default

    init() {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        rootURL = documents.appendingPathComponent("Pythonst3", isDirectory: true)
        projectsURL = rootURL.appendingPathComponent("Projects", isDirectory: true)
        try? fileManager.createDirectory(at: projectsURL, withIntermediateDirectories: true)
    }

    func folderURL(for project: Project) -> URL {
        projectsURL.appendingPathComponent(project.folderName, isDirectory: true)
    }

    func loadProjects() -> [Project] {
        let keys: [URLResourceKey] = [.isDirectoryKey]
        let urls = (try? fileManager.contentsOfDirectory(
            at: projectsURL,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        )) ?? []

        var projects: [Project] = []
        for url in urls {
            guard (try? url.resourceValues(forKeys: Set(keys)))?.isDirectory == true else { continue }
            let manifestURL = url.appendingPathComponent("project.json")
            guard let data = try? Data(contentsOf: manifestURL),
                  let manifest = try? JSONCoding.decoder.decode(StoredManifest.self, from: data) else {
                continue
            }
            projects.append(Project(
                id: manifest.id,
                name: manifest.name,
                folderName: url.lastPathComponent,
                entrypoint: manifest.entrypoint,
                createdAt: manifest.createdAt,
                updatedAt: manifest.updatedAt
            ))
        }
        return projects.sorted { $0.updatedAt > $1.updatedAt }
    }

    func createProject(name: String) throws -> Project {
        var project = try allocateProject(named: name)
        let folder = folderURL(for: project)
        try ProjectTemplates.starter.write(
            to: folder.appendingPathComponent("main.py"),
            atomically: true,
            encoding: .utf8
        )
        let now = Date()
        project.updatedAt = now
        let manifest = StoredManifest(
            format: "pythonst3-project",
            version: 1,
            id: project.id,
            name: project.name,
            entrypoint: project.entrypoint,
            createdAt: project.createdAt,
            updatedAt: now
        )
        try writeManifest(manifest, to: folder)
        return project
    }

    func loadFiles(for project: Project) throws -> [ScriptFile] {
        let folder = folderURL(for: project)
        guard fileManager.fileExists(atPath: folder.path) else { throw ProjectStoreError.notFound }
        let entrypoint = (try? readManifest(for: project))?.entrypoint ?? "main.py"
        let supported: Set<String> = ["py", "txt", "md", "json", "csv"]
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey]

        guard let enumerator = fileManager.enumerator(
            at: folder,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            throw ProjectStoreError.unreadable
        }

        var files: [ScriptFile] = []
        for case let url as URL in enumerator {
            guard supported.contains(url.pathExtension.lowercased()) else { continue }
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true else { continue }
            guard (values.fileSize ?? 0) <= 2_000_000 else { continue }
            let prefix = folder.path.hasSuffix("/") ? folder.path : folder.path + "/"
            guard url.path.hasPrefix(prefix) else { continue }
            let relative = String(url.path.dropFirst(prefix.count))
            guard isSafeRelativePath(relative) else { continue }
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { continue }
            files.append(ScriptFile(
                path: relative,
                content: content,
                isEntrypoint: relative == entrypoint
            ))
        }

        return files.sorted { lhs, rhs in
            if lhs.isEntrypoint != rhs.isEntrypoint { return lhs.isEntrypoint }
            return lhs.path.localizedStandardCompare(rhs.path) == .orderedAscending
        }
    }

    func save(file: ScriptFile, in project: Project) throws {
        let url = try safeURL(relativePath: file.path, in: project)
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try file.content.write(to: url, atomically: true, encoding: .utf8)
        var manifest = try readManifest(for: project)
        manifest.updatedAt = Date()
        try writeManifest(manifest, to: folderURL(for: project))
    }

    func createFile(named name: String, in project: Project) throws -> ScriptFile {
        var fileName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !fileName.isEmpty, fileName.count <= 80 else { throw ProjectStoreError.invalidName }
        if !fileName.contains(".") {
            fileName += ".py"
        }
        guard isSafeRelativePath(fileName) else { throw ProjectStoreError.invalidPath }
        let url = try safeURL(relativePath: fileName, in: project)
        guard !fileManager.fileExists(atPath: url.path) else { throw ProjectStoreError.alreadyExists }
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "".write(to: url, atomically: true, encoding: .utf8)
        return ScriptFile(path: fileName, content: "", isEntrypoint: false)
    }

    func deleteFile(path: String, in project: Project) throws {
        let url = try safeURL(relativePath: path, in: project)
        guard fileManager.fileExists(atPath: url.path) else { throw ProjectStoreError.notFound }
        try fileManager.removeItem(at: url)
        var manifest = try readManifest(for: project)
        manifest.updatedAt = Date()
        try writeManifest(manifest, to: folderURL(for: project))
    }

    func deleteProject(_ project: Project) throws {
        let folder = folderURL(for: project)
        guard fileManager.fileExists(atPath: folder.path) else { throw ProjectStoreError.notFound }
        try fileManager.removeItem(at: folder)
    }

    func archive(for project: Project) throws -> Data {
        let files = try loadFiles(for: project)
        let manifest = try readManifest(for: project)
        let archived = files.map { ArchivedFile(path: $0.path, content: $0.content) }
        let archive = ProjectArchive(
            format: "pythonst3-project",
            version: 1,
            name: project.name,
            entrypoint: manifest.entrypoint,
            files: archived,
            createdAt: project.createdAt,
            updatedAt: Date()
        )
        return try JSONCoding.encoder.encode(archive)
    }

    func importArchive(_ data: Data) throws -> Project {
        guard let archive = try? JSONCoding.decoder.decode(ProjectArchive.self, from: data),
              archive.format == "pythonst3-project",
              archive.version <= 1 else {
            throw ProjectStoreError.unreadable
        }
        guard archive.files.count <= 500 else { throw ProjectStoreError.tooLarge }

        var seen = Set<String>()
        var total = 0
        for file in archive.files {
            guard isSafeRelativePath(file.path), !seen.contains(file.path) else {
                throw ProjectStoreError.invalidPath
            }
            seen.insert(file.path)
            total += file.content.utf8.count
            if total > 20_000_000 { throw ProjectStoreError.tooLarge }
        }

        var project = try allocateProject(named: archive.name.isEmpty ? "Imported Project" : archive.name)
        var files = archive.files
        if files.isEmpty {
            files = [ArchivedFile(path: "main.py", content: "print('Hello from Pythonst3')\n")]
        }
        let entrypoint = files.contains(where: { $0.path == archive.entrypoint })
            ? archive.entrypoint
            : (files.first?.path ?? "main.py")

        let folder = folderURL(for: project)
        for file in files {
            let url = try safeURL(relativePath: file.path, in: project)
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try file.content.write(to: url, atomically: true, encoding: .utf8)
        }

        let now = Date()
        let manifest = StoredManifest(
            format: "pythonst3-project",
            version: 1,
            id: project.id,
            name: project.name,
            entrypoint: entrypoint,
            createdAt: now,
            updatedAt: now
        )
        try writeManifest(manifest, to: folder)
        project.entrypoint = entrypoint
        project.updatedAt = now
        return project
    }

    func importPythonFile(_ url: URL) throws -> Project {
        let content = try String(contentsOf: url, encoding: .utf8)
        let base = url.deletingPathExtension().lastPathComponent
        let project = try createProject(name: base.isEmpty ? "Imported Script" : base)
        let target = try safeURL(relativePath: "main.py", in: project)
        try content.write(to: target, atomically: true, encoding: .utf8)
        return project
    }

    func safeURL(relativePath: String, in project: Project) throws -> URL {
        guard isSafeRelativePath(relativePath) else { throw ProjectStoreError.invalidPath }
        let base = folderURL(for: project).standardizedFileURL
        let candidate = base.appendingPathComponent(relativePath).standardizedFileURL
        guard candidate.path.hasPrefix(base.path + "/") else { throw ProjectStoreError.invalidPath }
        return candidate
    }

    private func readManifest(for project: Project) throws -> StoredManifest {
        let url = folderURL(for: project).appendingPathComponent("project.json")
        let data = try Data(contentsOf: url)
        return try JSONCoding.decoder.decode(StoredManifest.self, from: data)
    }

    private func writeManifest(_ manifest: StoredManifest, to folder: URL) throws {
        let data = try JSONCoding.encoder.encode(manifest)
        try data.write(to: folder.appendingPathComponent("project.json"), options: .atomic)
    }

    private func allocateProject(named name: String) throws -> Project {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 60 else { throw ProjectStoreError.invalidName }
        let base = slug(trimmed)
        let folderName = "\(base)-\(UUID().uuidString.prefix(8).lowercased())"
        let folder = projectsURL.appendingPathComponent(folderName, isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        let now = Date()
        return Project(
            id: UUID(),
            name: trimmed,
            folderName: folderName,
            entrypoint: "main.py",
            createdAt: now,
            updatedAt: now
        )
    }

    private func slug(_ input: String) -> String {
        var result = ""
        for scalar in input.lowercased().unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                result.unicodeScalars.append(scalar)
            } else if !result.hasSuffix("-") {
                result.append("-")
            }
        }
        let trimmed = result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let limited = String(trimmed.prefix(40))
        return limited.isEmpty ? "project" : limited
    }
}
