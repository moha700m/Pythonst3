import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let pythonst3 = UTType(exportedAs: "com.moha700m.pythonst3", conformingTo: .json)
}

struct ProjectDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pythonst3, .json] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
