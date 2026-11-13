import Foundation

struct Project: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var folderName: String
    var entrypoint: String
    var createdAt: Date
    var updatedAt: Date
}

struct ScriptFile: Identifiable, Hashable {
    var id: String { path }
    var path: String
    var content: String
    var isEntrypoint: Bool
}

struct ConsoleLine: Identifiable, Hashable {
    enum Kind: String, Hashable {
        case stdout
        case stderr
        case info
        case command
        case input
        case success
    }

    let id: UUID
    let kind: Kind
    let text: String
    let date: Date

    init(kind: Kind, text: String) {
        self.id = UUID()
        self.kind = kind
        self.text = text
        self.date = Date()
    }
}

struct InputRequest: Identifiable, Equatable {
    let id = UUID()
    let prompt: String

    init(prompt: String) {
        self.prompt = prompt
    }
}

struct StoredManifest: Codable {
    var format: String
    var version: Int
    var id: UUID
    var name: String
    var entrypoint: String
    var createdAt: Date
    var updatedAt: Date
}

struct ArchivedFile: Codable {
    var path: String
    var content: String
}

struct ProjectArchive: Codable {
    var format: String
    var version: Int
    var name: String
    var entrypoint: String
    var files: [ArchivedFile]
    var createdAt: Date
    var updatedAt: Date
}
