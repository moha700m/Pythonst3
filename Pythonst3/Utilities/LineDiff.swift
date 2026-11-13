import Foundation

struct DiffLine: Identifiable {
    enum Kind {
        case equal
        case insert
        case delete
    }

    let id: Int
    let kind: Kind
    let text: String
    let oldNumber: Int?
    let newNumber: Int?
}

enum LineDiff {
    /// Line-based LCS diff. Files edited in Pythonst3 are small, so the quadratic
    /// table is acceptable; very large inputs fall back to a single replacement.
    static func compute(old: String, new: String) -> [DiffLine] {
        let oldLines = old.components(separatedBy: "\n")
        let newLines = new.components(separatedBy: "\n")

        guard oldLines.count * newLines.count <= 4_000_000 else {
            var fallback: [DiffLine] = []
            var index = 0
            for (offset, line) in oldLines.enumerated() {
                fallback.append(DiffLine(
                    id: index,
                    kind: .delete,
                    text: line,
                    oldNumber: offset + 1,
                    newNumber: nil
                ))
                index += 1
            }
            for (offset, line) in newLines.enumerated() {
                fallback.append(DiffLine(
                    id: index,
                    kind: .insert,
                    text: line,
                    oldNumber: nil,
                    newNumber: offset + 1
                ))
                index += 1
            }
            return fallback
        }

        var table = [[Int]](
            repeating: [Int](repeating: 0, count: newLines.count + 1),
            count: oldLines.count + 1
        )

        if !oldLines.isEmpty && !newLines.isEmpty {
            for i in stride(from: oldLines.count - 1, through: 0, by: -1) {
                for j in stride(from: newLines.count - 1, through: 0, by: -1) {
                    if oldLines[i] == newLines[j] {
                        table[i][j] = table[i + 1][j + 1] + 1
                    } else {
                        table[i][j] = max(table[i + 1][j], table[i][j + 1])
                    }
                }
            }
        }

        var result: [DiffLine] = []
        var i = 0
        var j = 0
        var identifier = 0

        while i < oldLines.count && j < newLines.count {
            if oldLines[i] == newLines[j] {
                result.append(DiffLine(
                    id: identifier,
                    kind: .equal,
                    text: oldLines[i],
                    oldNumber: i + 1,
                    newNumber: j + 1
                ))
                i += 1
                j += 1
            } else if table[i + 1][j] >= table[i][j + 1] {
                result.append(DiffLine(
                    id: identifier,
                    kind: .delete,
                    text: oldLines[i],
                    oldNumber: i + 1,
                    newNumber: nil
                ))
                i += 1
            } else {
                result.append(DiffLine(
                    id: identifier,
                    kind: .insert,
                    text: newLines[j],
                    oldNumber: nil,
                    newNumber: j + 1
                ))
                j += 1
            }
            identifier += 1
        }

        while i < oldLines.count {
            result.append(DiffLine(
                id: identifier,
                kind: .delete,
                text: oldLines[i],
                oldNumber: i + 1,
                newNumber: nil
            ))
            i += 1
            identifier += 1
        }

        while j < newLines.count {
            result.append(DiffLine(
                id: identifier,
                kind: .insert,
                text: newLines[j],
                oldNumber: nil,
                newNumber: j + 1
            ))
            j += 1
            identifier += 1
        }

        return result
    }

    static func counts(_ lines: [DiffLine]) -> (inserted: Int, removed: Int) {
        var inserted = 0
        var removed = 0
        for line in lines {
            switch line.kind {
            case .insert: inserted += 1
            case .delete: removed += 1
            case .equal: break
            }
        }
        return (inserted, removed)
    }
}
