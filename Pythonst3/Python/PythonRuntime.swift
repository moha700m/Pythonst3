import Foundation
import Darwin

enum RuntimeState: Equatable {
    case idle
    case preparing
    case ready
    case running
    case stopping
    case failed(String)

    var label: String {
        switch self {
        case .idle: return "غير مهيأ"
        case .preparing: return "جارٍ التهيئة"
        case .ready: return "جاهز"
        case .running: return "يعمل"
        case .stopping: return "جارٍ الإيقاف"
        case .failed: return "خطأ"
        }
    }

    var isBusy: Bool {
        self == .preparing || self == .running || self == .stopping
    }
}

final class PythonRuntime: ObservableObject {
    static let shared = PythonRuntime()

    @Published private(set) var state: RuntimeState = .idle
    @Published private(set) var lines: [ConsoleLine] = []
    @Published private(set) var pythonVersion: String = "—"
    @Published private(set) var lastExitCode: Int32 = 0
    @Published var pendingInput: InputRequest?

    private let queue = DispatchQueue(label: "com.moha700m.pythonst3.runtime", qos: .userInitiated)
    private var initialized = false

    private var stdoutBuffer = ""
    private var stderrBuffer = ""

    private let inputLock = NSLock()
    private var inputSemaphore: DispatchSemaphore?
    private var inputAnswer: String?
    private var stopRequested = false

    private init() {
        pythonst3_set_callbacks(pythonst3WriteCallback, pythonst3ReadlineCallback)
    }

    func prepare() {
        queue.async { [weak self] in
            guard let self else { return }
            if self.initialized { return }
            self.publish(.preparing)
            if self.initializeRuntime() {
                self.initialized = true
                let version = self.runtimeVersion()
                DispatchQueue.main.async {
                    self.pythonVersion = version
                    self.append("Python \(version) — المفسر المدمج جاهز", kind: .success)
                    self.state = .ready
                }
            } else {
                self.publish(.failed("تعذر تهيئة مفسر Python المدمج. راجع وحدة التحكم."))
            }
        }
    }

    func run(source: String, filename: String, projectURL: URL, timeout: Int) {
        if state.isBusy { return }
        inputLock.lock()
        stopRequested = false
        inputLock.unlock()

        flushBuffers()
        append("▶ \(filename)", kind: .command)
        state = .running

        queue.async { [weak self] in
            guard let self else { return }
            if !self.initialized {
                if !self.initializeRuntime() {
                    self.publish(.failed("تعذر تهيئة مفسر Python المدمج."))
                    return
                }
                self.initialized = true
                let version = self.runtimeVersion()
                DispatchQueue.main.async {
                    self.pythonVersion = version
                    self.state = .running
                }
            }

            pythonst3_set_timeout(Int32(max(1, min(timeout, 300))))
            let status = source.withCString { sourcePointer in
                filename.withCString { filenamePointer in
                    projectURL.path.withCString { directoryPointer in
                        pythonst3_execute(sourcePointer, filenamePointer, directoryPointer)
                    }
                }
            }

            DispatchQueue.main.async {
                self.flushBuffers()
                self.lastExitCode = status
                switch status {
                case 0:
                    self.append("✓ انتهى التنفيذ", kind: .success)
                case 2:
                    self.append("⏹ تم إيقاف التنفيذ", kind: .info)
                case 3:
                    self.append("⏹ خرج البرنامج عبر SystemExit", kind: .info)
                default:
                    self.append("✕ انتهى التنفيذ مع خطأ", kind: .stderr)
                }
                self.state = .ready
            }
        }
    }

    /// Executes one console entry against a persistent `__main__` namespace, so
    /// variables survive between entries. Expressions print through displayhook.
    func evaluateREPL(_ source: String, projectURL: URL, timeout: Int) {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !state.isBusy else { return }

        inputLock.lock()
        stopRequested = false
        inputLock.unlock()

        flushBuffers()
        append(">>> \(trimmed)", kind: .command)
        state = .running

        queue.async { [weak self] in
            guard let self else { return }
            if !self.initialized {
                if !self.initializeRuntime() {
                    self.publish(.failed("تعذر تهيئة مفسر Python المدمج."))
                    return
                }
                self.initialized = true
            }

            pythonst3_set_timeout(Int32(max(1, min(timeout, 300))))
            let payload = trimmed + "\n"
            let status = payload.withCString { sourcePointer in
                projectURL.path.withCString { directoryPointer in
                    pythonst3_repl(sourcePointer, directoryPointer)
                }
            }

            DispatchQueue.main.async {
                self.flushBuffers()
                self.lastExitCode = status
                switch status {
                case 0:
                    break
                case 2:
                    self.append("⏹ تم إيقاف الأمر", kind: .info)
                case 3:
                    self.append("⏹ خرج البرنامج عبر SystemExit", kind: .info)
                default:
                    self.append("✕ خطأ في الأمر", kind: .stderr)
                }
                self.state = .ready
            }
        }
    }

    func stop() {
        inputLock.lock()
        stopRequested = true
        inputLock.unlock()
        pythonst3_request_stop()
        finishInput(nil)
        DispatchQueue.main.async {
            if self.state == .running {
                self.state = .stopping
            }
        }
    }

    func provideInput(_ text: String) {
        finishInput(text)
    }

    func cancelInput() {
        finishInput(nil)
    }

    func clearConsole() {
        lines.removeAll()
        stdoutBuffer = ""
        stderrBuffer = ""
    }

    // MARK: - Native bridge entry points

    func receive(channel: Int32, text: String) {
        DispatchQueue.main.async {
            self.consume(text, channel: channel)
        }
    }

    func requestInputFromBridge(prompt: String) -> String? {
        let semaphore = DispatchSemaphore(value: 0)

        inputLock.lock()
        if stopRequested {
            inputLock.unlock()
            return nil
        }
        inputSemaphore = semaphore
        inputAnswer = nil
        inputLock.unlock()

        DispatchQueue.main.async {
            self.pendingInput = InputRequest(prompt: prompt)
        }

        semaphore.wait()

        inputLock.lock()
        let answer = inputAnswer
        inputSemaphore = nil
        inputLock.unlock()
        return answer
    }

    private func finishInput(_ text: String?) {
        inputLock.lock()
        guard let semaphore = inputSemaphore else {
            inputLock.unlock()
            return
        }
        inputSemaphore = nil
        inputAnswer = text
        inputLock.unlock()

        DispatchQueue.main.async {
            self.pendingInput = nil
        }
        semaphore.signal()
    }

    // MARK: - Runtime lifecycle

    private func initializeRuntime() -> Bool {
        guard let home = Bundle.main.path(forResource: "python", ofType: nil) else {
            report("لم يتم العثور على مجلد python داخل حزمة التطبيق.")
            return false
        }
        guard let executable = Bundle.main.executablePath else {
            report("تعذر تحديد مسار الملف التنفيذي للتطبيق.")
            return false
        }
        guard let bootstrapURL = Bundle.main.url(forResource: "bootstrap", withExtension: "py"),
              let bootstrap = try? String(contentsOf: bootstrapURL, encoding: .utf8) else {
            report("لم يتم العثور على bootstrap.py داخل الموارد.")
            return false
        }

        let status = home.withCString { homePointer in
            executable.withCString { executablePointer in
                bootstrap.withCString { bootstrapPointer in
                    pythonst3_initialize(homePointer, executablePointer, bootstrapPointer)
                }
            }
        }

        if status != 0 {
            report("فشل تهيئة Python (رمز \(status)).")
            return false
        }
        return true
    }

    private func runtimeVersion() -> String {
        let pointer = pythonst3_version()
        guard let pointer else { return "unknown" }
        return String(cString: pointer)
    }

    private func publish(_ newState: RuntimeState) {
        DispatchQueue.main.async {
            self.state = newState
        }
    }

    private func report(_ message: String) {
        DispatchQueue.main.async {
            self.append(message, kind: .stderr)
        }
    }

    // MARK: - Console buffering (main thread only)

    private func append(_ text: String, kind: ConsoleLine.Kind) {
        let cleaned = text.hasSuffix("\r") ? String(text.dropLast()) : text
        lines.append(ConsoleLine(kind: kind, text: cleaned))
        if lines.count > 2500 {
            lines.removeFirst(lines.count - 2500)
        }
    }

    private func consume(_ text: String, channel: Int32) {
        let isError = channel == 2
        var buffer = isError ? stderrBuffer : stdoutBuffer
        buffer += text
        let kind: ConsoleLine.Kind = isError ? .stderr : .stdout

        while let newline = buffer.firstIndex(of: "\n") {
            let line = String(buffer[..<newline])
            buffer = String(buffer[buffer.index(after: newline)...])
            append(line, kind: kind)
        }

        if buffer.count > 16_000 {
            append(buffer, kind: kind)
            buffer = ""
        }

        if isError {
            stderrBuffer = buffer
        } else {
            stdoutBuffer = buffer
        }
    }

    private func flushBuffers() {
        if !stdoutBuffer.isEmpty {
            append(stdoutBuffer, kind: .stdout)
            stdoutBuffer = ""
        }
        if !stderrBuffer.isEmpty {
            append(stderrBuffer, kind: .stderr)
            stderrBuffer = ""
        }
    }
}

func pythonst3WriteCallback(_ channel: Int32, _ text: UnsafePointer<CChar>?) {
    guard let text else { return }
    PythonRuntime.shared.receive(channel: channel, text: String(cString: text))
}

func pythonst3ReadlineCallback(_ prompt: UnsafePointer<CChar>?) -> UnsafeMutablePointer<CChar>? {
    let promptText = prompt.map { String(cString: $0) } ?? ""
    guard let answer = PythonRuntime.shared.requestInputFromBridge(prompt: promptText) else {
        return nil
    }
    return strdup(answer)
}
