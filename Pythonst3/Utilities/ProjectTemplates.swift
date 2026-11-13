import Foundation

/// Shared starter sources. The store writes `starter` for every new project, and the
/// UI uses `isPristine` to tell an untouched template apart from code the user wrote.
enum ProjectTemplates {
    static let starter = """
    # Pythonst3 — اكتب كودك هنا ثم اضغط «تشغيل».
    #
    # يمكنك لصق كود جاهز من الحافظة عبر زر «لصق» في شريط المحرر.

    def main():
        name = "Pythonst3"
        print(f"مرحباً من {name}")
        for step in range(1, 4):
            print("خطوة", step)
        print("جاهز للكتابة على iPhone")

    if __name__ == "__main__":
        main()
    """

    static func isPristine(_ text: String) -> Bool {
        normalize(text) == normalize(starter)
    }

    private static func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
