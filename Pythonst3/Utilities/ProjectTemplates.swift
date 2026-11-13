import Foundation

/// Starter sources. The store writes `ProjectTemplate.source` for every new
/// project, and the UI uses `ProjectTemplates.isPristine` to tell an untouched
/// starter apart from code the user wrote.
enum ProjectTemplates {
    static let starter = ProjectTemplate.starter.source

    static func isPristine(_ text: String) -> Bool {
        normalize(text) == normalize(starter)
    }

    private static func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum ProjectTemplate: String, CaseIterable, Identifiable {
    case starter
    case automation
    case data
    case api
    case files
    case math

    var id: String { rawValue }

    var title: String {
        switch self {
        case .starter: return "البداية"
        case .automation: return "أتمتة"
        case .data: return "تحليل بيانات"
        case .api: return "عميل API"
        case .files: return "ملفات"
        case .math: return "رياضيات"
        }
    }

    var subtitle: String {
        switch self {
        case .starter: return "ملف main.py مع طباعة ومرحب"
        case .automation: return "تنظيف قوائم وإزالة التكرار"
        case .data: return "statistics وحساب المتوسط والانحراف"
        case .api: return "urllib.request مع معالجة أخطاء"
        case .files: return "قراءة وكتابة ملفات داخل المشروع"
        case .math: return "منخل إراتوستينس للأعداد الأولية"
        }
    }

    var icon: String {
        switch self {
        case .starter: return "play.circle"
        case .automation: return "gearshape.2"
        case .data: return "chart.bar"
        case .api: return "network"
        case .files: return "folder"
        case .math: return "function"
        }
    }

    var defaultProjectName: String {
        switch self {
        case .starter: return "مشروعي الأول"
        case .automation: return "أتمتة"
        case .data: return "تحليل بيانات"
        case .api: return "عميل API"
        case .files: return "معالجة ملفات"
        case .math: return "رياضيات"
        }
    }

    var source: String {
        switch self {
        case .starter:
            return """
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

        case .automation:
            return """
            # أتمتة نصية: تنظيف قائمة مهام وإزالة التكرار.
            tasks = [
                "  مراجعة الكود  ",
                "كتابة الاختبارات",
                "  نشر التطبيق ",
                "مراجعة الكود",
            ]

            cleaned = []
            for task in tasks:
                name = task.strip()
                if name and name not in cleaned:
                    cleaned.append(name)

            print("المهام:")
            for index, name in enumerate(cleaned, 1):
                print(f"{index}. {name}")
            """

        case .data:
            return """
            # تحليل بيانات صغير باستخدام المكتبة القياسية فقط.
            import statistics

            temperatures = [31, 34, 29, 36, 33, 30, 35]

            print("القراءات:", temperatures)
            print("المتوسط:", round(statistics.mean(temperatures), 1))
            print("الوسيط:", statistics.median(temperatures))
            print("الانحراف المعياري:", round(statistics.pstdev(temperatures), 2))
            """

        case .api:
            return """
            # عميل HTTP صغير. يحتاج اتصالاً بالإنترنت.
            import urllib.request

            url = "https://api.github.com/zen"

            try:
                with urllib.request.urlopen(url, timeout=10) as response:
                    body = response.read().decode("utf-8")
                print("الحالة:", response.status)
                print("الرد:", body)
            except Exception as error:
                print("تعذر الاتصال:", error)
            """

        case .files:
            return """
            # كتابة وقراءة ملف داخل مجلد المشروع.
            from pathlib import Path

            path = Path("notes.txt")
            path.write_text("سطر أول\\nسطر ثانٍ\\n", encoding="utf-8")

            print(path.read_text(encoding="utf-8"))
            print("الحجم:", path.stat().st_size, "بايت")
            print("المسار:", path.resolve())
            """

        case .math:
            return """
            # الأعداد الأولية حتى حد معيّن.
            def primes(limit):
                sieve = [True] * (limit + 1)
                sieve[0:2] = [False, False]
                for number in range(2, int(limit ** 0.5) + 1):
                    if sieve[number]:
                        for multiple in range(number * number, limit + 1, number):
                            sieve[multiple] = False
                return [value for value, is_prime in enumerate(sieve) if is_prime]

            print("الأعداد الأولية حتى 50:")
            print(primes(50))
            """
        }
    }
}
