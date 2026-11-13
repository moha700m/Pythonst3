import SwiftUI
import UIKit

struct AIAssistantView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("ai.provider") private var provider = "openai"
    @AppStorage("ai.baseURL") private var baseURL = "https://api.openai.com/v1"
    @AppStorage("ai.model") private var model = "gpt-4o-mini"

    @State private var prompt = ""
    @State private var includeFile = false
    @State private var action = "شرح"
    @State private var response = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    private let actions = ["شرح", "تصحيح", "تحسين", "توليد", "اختبارات"]

    private var isConfigured: Bool {
        KeychainStore.read(account: AICredentials.account) != nil
    }

    private var canSend: Bool {
        isConfigured
            && !isLoading
            && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CyberBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        statusPanel
                        SectionLabel(text: "ACTION / الإجراء")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(actions, id: \.self) { item in
                                    Button(item) {
                                        action = item
                                    }
                                    .buttonStyle(CyberButtonStyle(
                                        tint: action == item ? CyberTheme.neonGreen : CyberTheme.textSecondary,
                                        filled: action == item
                                    ))
                                }
                            }
                        }

                        SectionLabel(text: "REQUEST / طلبك")
                        ZStack(alignment: .topLeading) {
                            if prompt.isEmpty {
                                Text("اطلب شرحاً للكود، تصحيح خطأ، تحسيناً، أو توليد ملف جديد…")
                                    .font(CyberTheme.arabic(13))
                                    .foregroundStyle(CyberTheme.textMuted)
                                    .padding(12)
                            }
                            TextEditor(text: $prompt)
                                .font(CyberTheme.arabic(14))
                                .foregroundStyle(CyberTheme.textPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 110)
                                .padding(6)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(CyberTheme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(CyberTheme.neonCyan.opacity(0.25), lineWidth: 1)
                        )

                        Toggle(isOn: $includeFile) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("إرفاق الملف الحالي")
                                    .font(CyberTheme.arabic(13, weight: .medium))
                                Text(app.activeFile?.path ?? "لا يوجد ملف مفتوح")
                                    .font(CyberTheme.mono(10))
                                    .foregroundStyle(CyberTheme.textMuted)
                            }
                        }
                        .tint(CyberTheme.neonGreen)
                        .disabled(app.activeFile == nil)

                        if includeFile, app.activeFile != nil {
                            Text("سيتم إرسال \(app.activeContent.count) حرفاً من «\(app.activeFile?.path ?? "")» مع طلبك.")
                                .font(CyberTheme.arabic(11))
                                .foregroundStyle(CyberTheme.amber)
                        }

                        Button {
                            Task { await send() }
                        } label: {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .tint(CyberTheme.background)
                                }
                                Text(isLoading ? "جارٍ الإرسال…" : "إرسال")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CyberButtonStyle(filled: true))
                        .disabled(!canSend)
                        .opacity(canSend ? 1 : 0.45)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(CyberTheme.arabic(12))
                                .foregroundStyle(CyberTheme.danger)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(CyberTheme.danger.opacity(0.08))
                                )
                        }

                        if !response.isEmpty {
                            responsePanel
                        }

                        if let block = suggestedBlock {
                            suggestionPanel(block)
                        }

                        Text("المساعد لا يعدّل ملفاتك تلقائياً. راجع أي كود قبل نسخه. لا تُرسل أسراراً أو مفاتيح داخل الطلب.")
                            .font(CyberTheme.arabic(11))
                            .foregroundStyle(CyberTheme.textMuted)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("المساعد الذكي")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("تم") {
                        dismiss()
                    }
                    .foregroundStyle(CyberTheme.neonCyan)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $app.pendingProposal) { proposal in
            DiffApprovalView(proposal: proposal)
        }
    }

    private var suggestedBlock: CodeExtraction.Block? {
        guard !response.isEmpty else { return nil }
        return CodeExtraction.preferredBlock(in: response)
    }

    private func suggestionPanel(_ block: CodeExtraction.Block) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 12))
                    .foregroundStyle(CyberTheme.neonGreen)
                Text("كود مقترح جاهز للمراجعة")
                    .font(CyberTheme.arabic(13, weight: .semibold))
                    .foregroundStyle(CyberTheme.textPrimary)
                Spacer(minLength: 4)
                Text("\(block.lineCount) سطراً")
                    .font(CyberTheme.mono(9.5))
                    .foregroundStyle(CyberTheme.textMuted)
            }

            Text("سيُطبَّق على «\(app.activeFile?.path ?? "لا يوجد ملف")» فقط بعد عرض الفرق وموافقتك.")
                .font(CyberTheme.arabic(11))
                .foregroundStyle(CyberTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                applySuggestion(block)
            } label: {
                Label("مراجعة الفرق وتطبيقه", systemImage: "diff")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CyberButtonStyle(filled: true))
            .disabled(app.activeFile == nil)
            .opacity(app.activeFile == nil ? 0.45 : 1)

            if app.activeFile == nil {
                Text("افتح ملفاً من مساحة العمل أولاً.")
                    .font(CyberTheme.arabic(10.5))
                    .foregroundStyle(CyberTheme.amber)
            }
        }
        .padding(12)
        .neonPanel(accent: CyberTheme.neonGreen, cornerRadius: 12)
    }

    private func applySuggestion(_ block: CodeExtraction.Block) {
        guard let file = app.activeFile else {
            errorMessage = "افتح ملفاً أولاً لتطبيق الاقتراح."
            return
        }
        app.proposeAssistantCode(block.code, path: file.path, summary: action)
    }

    private var statusPanel: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isConfigured ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isConfigured ? CyberTheme.neonGreen : CyberTheme.amber)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 3) {
                Text(isConfigured ? "المساعد مهيأ" : "المساعد غير مهيأ")
                    .font(CyberTheme.arabic(14, weight: .semibold))
                    .foregroundStyle(CyberTheme.textPrimary)
                Text(isConfigured
                     ? "\(provider) · \(model)"
                     : "أضف مفتاح API من الإعدادات لتفعيل الإرسال. لن يُرسل أي شيء قبل ذلك.")
                    .font(CyberTheme.arabic(11))
                    .foregroundStyle(CyberTheme.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .neonPanel(accent: isConfigured ? CyberTheme.neonGreen : CyberTheme.amber, cornerRadius: 12)
    }

    private var responsePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel(text: "RESPONSE / الرد")
                Spacer()
                Button {
                    UIPasteboard.general.string = response
                } label: {
                    Label("نسخ", systemImage: "doc.on.doc")
                        .font(CyberTheme.arabic(11))
                }
                .buttonStyle(CyberButtonStyle(tint: CyberTheme.neonCyan))
            }
            Text(response)
                .font(CyberTheme.arabic(14))
                .foregroundStyle(CyberTheme.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .neonPanel(accent: CyberTheme.neonCyan, cornerRadius: 12)
    }

    @MainActor
    private func send() async {
        guard let key = KeychainStore.read(account: AICredentials.account), !key.isEmpty else {
            errorMessage = "أضف مفتاح API من الإعدادات أولاً."
            return
        }
        guard URL(string: baseURL) != nil else {
            errorMessage = "عنوان Base URL غير صالح."
            return
        }

        let kind = AIProviderKind(rawValue: provider) ?? .openAI
        let configuration = AIConfiguration(
            provider: kind,
            baseURL: baseURL,
            model: model,
            apiKey: key
        )

        isLoading = true
        errorMessage = nil
        response = ""

        var userText = "الإجراء المطلوب: \(action)\n\n\(prompt)"
        if includeFile, let file = app.activeFile {
            let excerpt = String(file.content.prefix(12_000))
            userText += "\n\nالملف الحالي (\(file.path)):\n```python\n\(excerpt)\n```"
        }

        let messages = [
            ChatMessage(
                role: "system",
                content: "أنت مساعد برمجي خبير داخل تطبيق Pythonst3 لمحرر Python على iOS. أجب بالعربية بوضوح ودقة. لا تدّع تشغيل كود لم تره. عند اقتراح تعديلات اعرض الكود كاملاً في كتلة كود."
            ),
            ChatMessage(role: "user", content: userText)
        ]

        do {
            response = try await AIClient().complete(messages: messages, configuration: configuration)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
