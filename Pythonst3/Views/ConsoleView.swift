import SwiftUI

struct ConsoleView: View {
    @ObservedObject var runtime: PythonRuntime
    @Binding var expanded: Bool

    @AppStorage("console.fontSize") private var fontSize: Double = 12
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .overlay(CyberTheme.neonCyan.opacity(0.15))

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        if runtime.lines.isEmpty {
                            Text("لا يوجد إخراج بعد — اضغط زر التشغيل لتنفيذ الكود.")
                                .font(CyberTheme.mono(11))
                                .foregroundStyle(CyberTheme.textMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        }
                        ForEach(runtime.lines) { line in
                            ConsoleLineView(line: line, fontSize: CGFloat(fontSize))
                                .id(line.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: runtime.lines.count) { _ in
                    if let last = runtime.lines.last {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            if let pending = runtime.pendingInput {
                inputBar(pending)
            }
        }
        .frame(height: expanded ? 300 : 140)
        .background(CyberTheme.surface.opacity(0.96))
        .overlay(
            Rectangle()
                .fill(CyberTheme.neonCyan.opacity(0.18))
                .frame(height: 1),
            alignment: .top
        )
        .onChange(of: runtime.pendingInput?.id) { _ in
            if runtime.pendingInput != nil {
                inputText = ""
                inputFocused = true
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 10))
                .foregroundStyle(CyberTheme.neonCyan)
            Text("CONSOLE")
                .font(CyberTheme.mono(10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(CyberTheme.textSecondary)
            Spacer()
            StatusPill(text: runtime.state.label, color: statusColor)
            Button {
                runtime.clearConsole()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundStyle(CyberTheme.textSecondary)
            }
            .accessibilityLabel("مسح وحدة التحكم")
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expanded.toggle()
                }
            } label: {
                Image(systemName: expanded ? "chevron.down" : "chevron.up")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CyberTheme.textSecondary)
            }
            .accessibilityLabel(expanded ? "تصغير وحدة التحكم" : "توسيع وحدة التحكم")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    private var statusColor: Color {
        switch runtime.state {
        case .ready: return CyberTheme.neonGreen
        case .running: return CyberTheme.neonCyan
        case .preparing, .stopping: return CyberTheme.amber
        case .failed: return CyberTheme.danger
        case .idle: return CyberTheme.textMuted
        }
    }

    private func inputBar(_ pending: InputRequest) -> some View {
        HStack(spacing: 8) {
            Text(pending.prompt.isEmpty ? "input()" : pending.prompt)
                .font(CyberTheme.mono(11))
                .foregroundStyle(CyberTheme.amber)
                .lineLimit(1)
            TextField("أدخل قيمة ثم اضغط إرسال…", text: $inputText)
                .font(CyberTheme.mono(12))
                .foregroundStyle(CyberTheme.textPrimary)
                .textFieldStyle(.plain)
                .focused($inputFocused)
                .onSubmit {
                    submitInput()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(CyberTheme.background)
                )
            Button("إرسال") {
                submitInput()
            }
            .buttonStyle(CyberButtonStyle(tint: CyberTheme.amber))
            Button("إلغاء") {
                runtime.cancelInput()
            }
            .buttonStyle(CyberButtonStyle(tint: CyberTheme.textSecondary))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(CyberTheme.surfaceElevated)
    }

    private func submitInput() {
        let value = inputText
        inputText = ""
        runtime.provideInput(value)
    }
}

struct ConsoleLineView: View {
    let line: ConsoleLine
    let fontSize: CGFloat

    var body: some View {
        Text(line.text.isEmpty ? " " : line.text)
            .font(CyberTheme.mono(fontSize))
            .foregroundStyle(color)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var color: Color {
        switch line.kind {
        case .stdout: return CyberTheme.textPrimary
        case .stderr: return CyberTheme.danger
        case .info: return CyberTheme.textSecondary
        case .command: return CyberTheme.neonCyan
        case .input: return CyberTheme.amber
        case .success: return CyberTheme.neonGreen
        }
    }
}
