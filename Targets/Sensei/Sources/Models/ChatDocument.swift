import SwiftUI
import UniformTypeIdentifiers

struct ChatDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.markdown] }

    private var data: Data

    init(data: Data?) {
        self.data = data ?? .init()
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents
        else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: data)
    }
}

extension UTType {
    static let markdown = Self(filenameExtension: "md", conformingTo: .plainText)!
}
