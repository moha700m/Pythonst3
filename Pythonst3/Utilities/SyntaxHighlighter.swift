import SwiftUI
import UIKit

enum PythonHighlighter {
    private static let rules: [(NSRegularExpression, UIColor)] = {
        let number = UIColor(CyberTheme.codeNumber)
        let keyword = UIColor(CyberTheme.codeKeyword)
        let function = UIColor(CyberTheme.codeFunction)
        let decorator = UIColor(CyberTheme.neonMagenta)
        let comment = UIColor(CyberTheme.codeComment)
        let string = UIColor(CyberTheme.codeString)

        let specs: [(String, UIColor, NSRegularExpression.Options)] = [
            ("\\b(def|class)\\s+([A-Za-z_][A-Za-z0-9_]*)", function, []),
            ("\\b(0[xX][0-9a-fA-F]+|0[bB][01]+|\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?)\\b", number, []),
            ("\\b(and|as|assert|async|await|break|class|continue|def|del|elif|else|except|False|finally|for|from|global|if|import|in|is|lambda|None|nonlocal|not|or|pass|raise|return|True|try|while|with|yield)\\b", keyword, []),
            ("^\\s*@[A-Za-z_][A-Za-z0-9_.]*", decorator, [.anchorsMatchLines]),
            ("#[^\\n]*", comment, []),
            ("\"\"\"[\\s\\S]*?\"\"\"", string, []),
            ("'''[\\s\\S]*?'''", string, []),
            ("\"[^\"\\n]*\"", string, []),
            ("'[^'\\n]*'", string, [])
        ]

        return specs.compactMap { spec in
            guard let regex = try? NSRegularExpression(pattern: spec.0, options: spec.2) else {
                return nil
            }
            return (regex, spec.1)
        }
    }()

    static func highlight(_ text: String, font: UIFont, baseColor: UIColor) -> NSAttributedString {
        let attributed = NSMutableAttributedString(
            string: text,
            attributes: [.font: font, .foregroundColor: baseColor]
        )
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        guard fullRange.length > 0 else { return attributed }

        for (regex, color) in rules {
            regex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
                guard let match = match else { return }
                attributed.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        }
        return attributed
    }
}
