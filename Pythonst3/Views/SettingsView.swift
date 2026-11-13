import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("editor.fontSize") private var editorFontSize = 14.0
    @AppStorage("console.fontSize") private var consoleFontSize = 12.0
    @AppStorage("runtime.timeout") private var timeout = 30

    @AppStorage("ai.provider") private var provider = "openai"
    @AppStorage("ai.baseURL") private var baseURL = "https://api.openai.com/v1"
    @AppStorage("ai.model") private var model = "gpt-4o-mini"

    @State private var apiKey = ""
    @State private var keyConfigured = false
    @State private var keyMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("المحرر") {
                    HStack {
                        Text("حجم خط المحرر")
                        Spacer()
                        Text("\(Int(editorFontSize)) pt")
                            .font(CyberTheme.mono(12))
                            .foregroundStyle(CyberTheme.textSecondary)
                    }
                    Slider(value: $editorFontSize, in: 10...24, step: 1)
                        .tint(CyberTheme.neonGreen)

                    HStack {
                        Text("حجم خط وحدة التحكم")
                        Spacer()
                        Text("\(Int(consoleFontSize)) pt")
                            .font(CyberTheme.mono(12))
                            .foregroundStyle(CyberTheme.textSecondary)
                    }
                    Slider(value: $consoleFontSize, in: 9...20, step: 1)
                        .tint(CyberTheme.neonCyan)
                }

                Section("التشغيل") {
                    Stepper("مهلة التنفيذ: \(timeout) ثانية", value: $timeout, in: 5...120, step: 5)
                    Text("زر الإيقاف يستخدم trace hook لكل سطر. الأكواد التي تعطّل التتبع أو تنفّذ عمليات أصلية طويلة قد لا تتوقف فوراً.")
                        .font(CyberTheme.arabic(11))
                        .foregroundStyle(CyberTheme.textMuted)
                }

                Section("المساعد الذكي") {
                    Picker("المزود", selection: $provider) {
                        Text("OpenAI متوافق").tag("openai")
                        Text("Anthropic").tag("anthropic")
                    }

                    TextField("Base URL", text: $baseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .font(CyberTheme.mono(12))

                    TextField("Model", text: $model)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(CyberTheme.mono(12))

                    if keyConfigured {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(CyberTheme.neonGreen)
                            Text("مفتاح API محفوظ في Keychain")
                                .font(CyberTheme.arabic(12))
                                .foregroundStyle(CyberTheme.textSecondary)
                        }
                    }

                    SecureField(
                        keyConfigured ? "أدخل مفتاحاً جديداً للاستبدال" : "أدخل مفتاح API",
                        text: $apiKey
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(CyberTheme.mono(12))

                    HStack(spacing: 10) {
                        Button("حفظ المفتاح") {
                            saveKey()
                        }
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        if keyConfigured {
                            Button("حذف المفتاح", role: .destructive) {
                                KeychainStore.delete(account: AICredentials.account)
                                keyConfigured = false
                                apiKey = ""
                                keyMessage = "تم حذف المفتاح من Keychain."
                            }
                        }
                    }

                    if let keyMessage {
                        Text(keyMessage)
                            .font(CyberTheme.arabic(11))
                            .foregroundStyle(CyberTheme.neonGreen)
                    }

                    Text("لا يُرسل أي كود تلقائياً. يظهر ما سيُرسل قبل الإرسال، ويُخزَّن المفتاح في Keychain فقط — لا في ملفات المشروع أو سجلات التطبيق.")
                        .font(CyberTheme.arabic(11))
                        .foregroundStyle(CyberTheme.textMuted)
                }

                Section("عن التطبيق") {
                    LabeledContent("الإصدار", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    LabeledContent("معرّف الحزمة", value: Bundle.main.bundleIdentifier ?? "—")
                    LabeledContent("Python", value: PythonRuntime.shared.pythonVersion)
                    Link("ترخيص Python", destination: URL(string: "https://docs.python.org/3/license.html")!)
                    Link("Python-Apple-support", destination: URL(string: "https://github.com/beeware/Python-Apple-support")!)
                }

                Section("الخصوصية") {
                    Text("يعمل CPython داخل sandbox التطبيق. لا يوجد subprocess أو shell أو وصول عام لنظام الملفات. المشاريع محلية، والتصدير يدوي عبر Files.")
                        .font(CyberTheme.arabic(12))
                        .foregroundStyle(CyberTheme.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(CyberTheme.background)
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("تم") {
                        dismiss()
                    }
                    .foregroundStyle(CyberTheme.neonGreen)
                }
            }
            .onAppear {
                keyConfigured = KeychainStore.read(account: AICredentials.account) != nil
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveKey() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if KeychainStore.save(trimmed, account: AICredentials.account) {
            apiKey = ""
            keyConfigured = true
            keyMessage = "تم حفظ المفتاح في Keychain."
        } else {
            keyMessage = "تعذر حفظ المفتاح."
        }
    }
}
