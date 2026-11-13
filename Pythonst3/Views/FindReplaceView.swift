import SwiftUI

struct FindReplaceView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var replacement = ""
    @State private var caseSensitive = false
    @State private var current = 0
    @State private var status = ""

    private var options: NSString.CompareOptions {
        caseSensitive ? [] : [.caseInsensitive]
    }

    private var matches: [NSRange] {
        guard !query.isEmpty else { return [] }
        let content = app.activeContent as NSString
        var result: [NSRange] = []
        var location = 0
        while location < content.length {
            let searchRange = NSRange(location: location, length: content.length - location)
            let found = content.range(of: query, options: options, range: searchRange)
            if found.location == NSNotFound { break }
            result.append(found)
            location = found.location + max(found.length, 1)
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CyberBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        field(title: "SEARCH / ابحث عن", text: $query, placeholder: "print")
                        field(title: "REPLACE / استبدل بـ", text: $replacement, placeholder: "اتركه فارغاً للحذف")

                        Toggle(isOn: $caseSensitive) {
                            Text("حساس لحالة الأحرف")
                                .font(CyberTheme.arabic(12))
                                .foregroundStyle(CyberTheme.textSecondary)
                        }
                        .tint(CyberTheme.neonGreen)

                        HStack(spacing: 8) {
                            StatusPill(
                                text: matches.isEmpty ? "لا نتائج" : "\(matches.count) نتيجة",
                                color: matches.isEmpty ? CyberTheme.textMuted : CyberTheme.neonGreen
                            )
                            if !status.isEmpty {
                                Text(status)
                                    .font(CyberTheme.arabic(11))
                                    .foregroundStyle(CyberTheme.neonCyan)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }

                        HStack(spacing: 8) {
                            Button {
                                step(-1)
                            } label: {
                                Label("السابق", systemImage: "chevron.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(CyberButtonStyle(tint: CyberTheme.textSecondary))

                            Button {
                                step(1)
                            } label: {
                                Label("التالي", systemImage: "chevron.down")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(CyberButtonStyle(tint: CyberTheme.neonCyan))
                        }

                        Button {
                            replaceCurrent()
                        } label: {
                            Label("استبدال المحدد", systemImage: "arrow.left.arrow.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CyberButtonStyle(tint: CyberTheme.amber))

                        Button {
                            replaceAll()
                        } label: {
                            Label("استبدال الكل", systemImage: "square.stack.3d.down.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CyberButtonStyle(filled: true))

                        Text("البحث يعمل داخل الملف النشط فقط. الاستبدال يحفظ الملف تلقائياً.")
                            .font(CyberTheme.arabic(10.5))
                            .foregroundStyle(CyberTheme.textMuted)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("بحث واستبدال")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("تم") {
                        dismiss()
                    }
                    .foregroundStyle(CyberTheme.neonCyan)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: query) { _ in
            current = 0
            status = ""
        }
    }

    private func field(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionLabel(text: title)
            TextField(placeholder, text: text)
                .font(CyberTheme.mono(13))
                .foregroundStyle(CyberTheme.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(11)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(CyberTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(CyberTheme.neonCyan.opacity(0.22), lineWidth: 1)
                )
        }
    }

    private func step(_ delta: Int) {
        let all = matches
        guard !all.isEmpty else {
            status = "لا توجد نتائج"
            return
        }
        let count = all.count
        let next = ((current + delta) % count + count) % count
        current = next
        app.editorSelection = all[next]
        status = "\(next + 1) من \(count)"
    }

    private func replaceCurrent() {
        guard !query.isEmpty else { return }
        let all = matches
        guard !all.isEmpty else {
            status = "لا توجد نتائج"
            return
        }
        let index = min(max(current, 0), all.count - 1)
        let target = all[index]
        let updated = (app.activeContent as NSString).replacingCharacters(in: target, with: replacement)
        app.updateActiveContent(updated)
        app.saveActiveNow()
        app.editorSelection = NSRange(
            location: target.location + (replacement as NSString).length,
            length: 0
        )
        status = "تم الاستبدال"
    }

    private func replaceAll() {
        guard !query.isEmpty else { return }
        let content = app.activeContent as NSString
        let count = matches.count
        guard count > 0 else {
            status = "لا توجد نتائج"
            return
        }
        let updated = content.replacingOccurrences(
            of: query,
            with: replacement,
            options: options,
            range: NSRange(location: 0, length: content.length)
        )
        app.updateActiveContent(updated)
        app.saveActiveNow()
        status = "تم استبدال \(count) مطابقة"
    }
}
