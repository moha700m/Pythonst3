import Foundation

enum AICredentials {
    static let account = "ai.api-key"
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

enum AIProviderKind: String, CaseIterable, Identifiable {
    case openRouter = "openrouter"
    case openAI = "openai"
    case anthropic = "anthropic"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openRouter: return "OpenRouter"
        case .openAI: return "OpenAI متوافق"
        case .anthropic: return "Anthropic"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .openRouter: return "https://openrouter.ai/api/v1"
        case .openAI: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com/v1"
        }
    }

    var defaultModel: String {
        switch self {
        case .openRouter: return "openai/gpt-4o-mini"
        case .openAI: return "gpt-4o-mini"
        case .anthropic: return "claude-3-5-sonnet-latest"
        }
    }
}

struct AIConfiguration {
    var provider: AIProviderKind
    var baseURL: String
    var model: String
    var apiKey: String

    var isConfigured: Bool {
        !baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !apiKey.isEmpty
    }
}

enum AIClientError: LocalizedError {
    case notConfigured
    case invalidURL
    case http(Int, String)
    case emptyResponse
    case decoding

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "المساعد غير مهيأ. أضف مفتاح API من الإعدادات."
        case .invalidURL:
            return "عنوان خدمة AI غير صالح."
        case .http(let code, let message):
            return "فشل الطلب (\(code)): \(message)"
        case .emptyResponse:
            return "لم تُرجع الخدمة أي نص."
        case .decoding:
            return "تعذر قراءة استجابة خدمة AI."
        }
    }
}

final class AIClient {
    func complete(messages: [ChatMessage], configuration: AIConfiguration) async throws -> String {
        guard configuration.isConfigured else { throw AIClientError.notConfigured }
        switch configuration.provider {
        case .openRouter, .openAI:
            return try await openAI(messages: messages, configuration: configuration)
        case .anthropic:
            return try await anthropic(messages: messages, configuration: configuration)
        }
    }

    private func openAI(messages: [ChatMessage], configuration: AIConfiguration) async throws -> String {
        guard var url = URL(string: configuration.baseURL) else { throw AIClientError.invalidURL }
        if !url.path.hasSuffix("/chat/completions") {
            url.appendPathComponent("chat/completions")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        if configuration.provider == .openRouter {
            request.setValue("https://github.com/moha700m/Pythonst3", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("Pythonst3", forHTTPHeaderField: "X-Title")
        }

        let body: [String: Any] = [
            "model": configuration.model,
            "temperature": 0.2,
            "messages": messages.map { ["role": $0.role, "content": $0.content] }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String,
              !content.isEmpty else {
            throw AIClientError.decoding
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func anthropic(messages: [ChatMessage], configuration: AIConfiguration) async throws -> String {
        guard var url = URL(string: configuration.baseURL) else { throw AIClientError.invalidURL }
        if !url.path.hasSuffix("/messages") {
            url.appendPathComponent("messages")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let system = messages.first(where: { $0.role == "system" })?.content ?? ""
        let chat = messages.filter { $0.role != "system" }
        let body: [String: Any] = [
            "model": configuration.model,
            "max_tokens": 2048,
            "system": system,
            "messages": chat.map { ["role": $0.role, "content": $0.content] }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = (json["content"] as? [[String: Any]])?.first?["text"] as? String,
              !content.isEmpty else {
            throw AIClientError.decoding
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw AIClientError.http(http.statusCode, String(text.prefix(500)))
        }
    }
}
