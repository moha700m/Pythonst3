import Foundation

/// Pulls fenced code blocks out of an assistant reply so the UI can offer an
/// explicit review-and-apply step instead of asking the user to copy by hand.
enum CodeExtraction {
    struct Block {
        let language: String?
        let code: String

        var lineCount: Int {
            code.isEmpty ? 0 : code.components(separatedBy: "\n").count
        }
    }

    static func blocks(in text: String) -> [Block] {
        var result: [Block] = []
        var buffer: [String] = []
        var language: String?
        var inside = false

        for line in text.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                if inside {
                    let code = buffer.joined(separator: "\n")
                    if !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        result.append(Block(language: language, code: code))
                    }
                    buffer.removeAll()
                    inside = false
                    language = nil
                } else {
                    inside = true
                    let tag = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    language = tag.isEmpty ? nil : tag
                }
                continue
            }
            if inside {
                buffer.append(line)
            }
        }

        return result
    }

    static func preferredBlock(in text: String) -> Block? {
        let all = blocks(in: text)
        if let python = all.first(where: { ($0.language ?? "").lowercased().contains("py") }) {
            return python
        }
        return all.first
    }
}
