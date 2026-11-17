import Foundation

enum LLMAppsError: LocalizedError {
    case http(status: Int, message: String)
    case api(String)
    case notAllowed
    case tooManyPending
    case spendingLimit
    case emptyResponse
    case timeout

    var errorDescription: String? {
        switch self {
        case .http(let status, _):
            return LocalizedText(
                "Server error (\(status)). Please try again.", ru: "Ошибка сервера (\(status)). Попробуй ещё раз."
            ).value
        case .api:
            return LocalizedText(
                "Generation failed. Please try again later.", ru: "Не удалось сгенерировать. Попробуй позже."
            ).value
        case .notAllowed:
            return LocalizedText("This feature is temporarily unavailable.", ru: "Функция временно недоступна.").value
        case .tooManyPending:
            return LocalizedText(
                "Too many generations at once. Wait a moment.", ru: "Слишком много генераций сразу. Подожди немного."
            ).value
        case .spendingLimit:
            return LocalizedText("The service is temporarily unavailable.", ru: "Сервис временно недоступен.").value
        case .emptyResponse:
            return LocalizedText("Empty response. Please try again.", ru: "Пустой ответ. Попробуй ещё раз.").value
        case .timeout:
            return LocalizedText("It's taking too long. Please try again.", ru: "Слишком долго. Попробуй ещё раз.")
                .value
        }
    }

    var isRetryable: Bool {
        switch self {
        case .http(let status, _):
            return status >= 500 || status == 408
        case .timeout, .emptyResponse:
            return true
        default:
            return false
        }
    }
}

/// Client for the LLMApps proxy backend (chat completions + media generation).
final class LLMAppsClient {
    private let session: URLSession
    private let mediaLimiter = AsyncLimiter(limit: 3)

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 300
        configuration.waitsForConnectivity = false
        session = URLSession(configuration: configuration)
    }

    // MARK: Chat

    struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String?
            }

            let message: Message
        }

        let choices: [Choice]
    }

    /// Sends `messages` (OpenAI-compatible dictionaries) and returns the assistant text.
    func chat(
        messages: [[String: Any]],
        maxTokens: Int = 400,
        responseFormat: [String: Any]? = nil
    ) async throws -> String {
        var body: [String: Any] = [
            "messages": messages,
            "max_tokens": maxTokens,
        ]
        if let responseFormat {
            body["response_format"] = responseFormat
        }
        let data = try await withRetry {
            try await self.send(path: "/v1/chat/completions", body: body, timeout: 60)
        }
        let response = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = response.choices.first?.message.content, !content.isEmpty else {
            throw LLMAppsError.emptyResponse
        }
        return content
    }

    // MARK: Media

    struct MediaResult: Decodable {
        let id: String?
        let urls: [String]?
        let seed: Int?
        let error: String?
    }

    private struct AsyncEnvelope: Decodable {
        let id: String
        let status: String
        let result: MediaResult?
        let error: String?
    }

    /// Text-to-image through the async endpoint with status polling. Returns remote image URLs.
    func textToImage(
        prompt: String,
        negativePrompt: String? = nil,
        imageSize: String = "portrait_4_3",
        numImages: Int = 1,
        seed: Int? = nil
    ) async throws -> [URL] {
        var body: [String: Any] = [
            "prompt": prompt,
            "model": "default",
            "image_size": imageSize,
            "num_images": numImages,
            "output_format": "jpeg",
            "enable_safety_checker": true,
        ]
        if let negativePrompt {
            body["negative_prompt"] = negativePrompt
        }
        if let seed {
            body["seed"] = seed
        }
        let result = try await generateMedia(type: "text2image", body: body)
        let urls = (result.urls ?? []).compactMap(URL.init(string:))
        guard !urls.isEmpty else {
            throw LLMAppsError.emptyResponse
        }
        return urls
    }

    func download(_ url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw LLMAppsError.http(status: http.statusCode, message: "download")
        }
        return data
    }

    /// Text-to-speech (at most 500 characters per request). Returns the remote audio URL.
    func textToSpeech(text: String, voiceID: String, speed: Double) async throws -> URL {
        let body: [String: Any] = [
            "text": text,
            "model": "default",
            "voice_id": voiceID,
            "voice_speed": speed,
        ]
        let result = try await generateMedia(type: "text2speech", body: body)
        guard let url = (result.urls ?? []).compactMap(URL.init(string:)).first else {
            throw LLMAppsError.emptyResponse
        }
        return url
    }

    private func generateMedia(type: String, body: [String: Any]) async throws -> MediaResult {
        await mediaLimiter.acquire()
        defer { mediaLimiter.release() }

        let submitData = try await withRetry {
            try await self.send(path: "/media/\(type)/async", body: body, timeout: 120)
        }
        var envelope = try decodeEnvelope(submitData)
        let deadline = Date().addingTimeInterval(15 * 60)

        while envelope.status == "queued" || envelope.status == "in_progress" {
            if Date() > deadline {
                throw LLMAppsError.timeout
            }
            let delay: UInt64 = envelope.status == "queued" ? 3_000_000_000 : 2_000_000_000
            try await Task.sleep(nanoseconds: delay)
            let statusData = try await withRetry {
                try await self.send(path: "/media/status/\(envelope.id)", body: nil, timeout: 30)
            }
            envelope = try decodeEnvelope(statusData)
        }

        guard envelope.status == "completed", let result = envelope.result else {
            throw Self.apiError(envelope.error ?? "Generation failed")
        }
        if let error = result.error {
            throw Self.apiError(error)
        }
        return result
    }

    /// The provider reports an exhausted balance as a generic error text, which retrying cannot fix.
    private static func apiError(_ message: String) -> LLMAppsError {
        #if DEBUG
            print("LLMApps media error: \(message)")
        #endif
        if message.contains("TOP_UP") || message.contains("User is locked") {
            return .spendingLimit
        }
        return .api(message)
    }

    private func decodeEnvelope(_ data: Data) throws -> AsyncEnvelope {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            object["status"] == nil,
            let error = object["error"] as? String
        {
            throw Self.apiError(error)
        }
        return try JSONDecoder().decode(AsyncEnvelope.self, from: data)
    }

    // MARK: Transport

    private func send(path: String, body: [String: Any]?, timeout: TimeInterval) async throws -> Data {
        try Task.checkCancellation()
        guard AIConsentStore.shared.request() else {
            throw AIConsentError.required
        }
        var request = URLRequest(url: APICredentials.baseURL.appendingPathComponent(path))
        request.timeoutInterval = timeout
        request.setValue("Bearer \(TOTPTokenGenerator.token())", forHTTPHeaderField: "Authorization")
        if let body {
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } else {
            request.httpMethod = "GET"
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw LLMAppsError.timeout
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw mapError(status: status, data: data)
        }
        return data
    }

    private func mapError(status: Int, data: Data) -> LLMAppsError {
        let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        let code = object?["error"] as? String ?? ""
        switch (status, code) {
        case (429, _):
            return .tooManyPending
        case (402, _):
            return .spendingLimit
        case (403, "media_type_not_allowed"):
            return .notAllowed
        default:
            let message = String(data: data.prefix(300), encoding: .utf8) ?? ""
            return .http(status: status, message: message)
        }
    }

    private func withRetry(_ operation: () async throws -> Data) async throws -> Data {
        var attempt = 0
        while true {
            do {
                return try await operation()
            } catch let error as LLMAppsError where error.isRetryable && attempt < 2 {
                attempt += 1
                try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
            }
        }
    }
}

/// Limits the number of concurrently running operations (LLMApps allows 3 pending generations).
final class AsyncLimiter {
    private let limit: Int
    private var running = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(limit: Int) {
        self.limit = limit
    }

    func acquire() async {
        if running < limit {
            running += 1
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func release() {
        if waiters.isEmpty {
            running -= 1
        } else {
            waiters.removeFirst().resume()
        }
    }
}
