import Foundation

/// Результат автоопределения импорта: одиночная ссылка / список серверов / ошибка
enum ImportResult {
    case single(VPNConfiguration)
    case servers([VPNConfiguration])
    case failure(String)
}

/// Сервис импорта VPN-конфигураций.
///
/// Поддерживает:
/// - одиночные ссылки `vless://` / `vmess://`;
/// - https-подписки (тело — base64-кодированный список ссылок, либо plain-text список);
/// - «сырой» base64-блок вставленный напрямую.
final class SubscriptionService {

    static let shared = SubscriptionService()

    private init() {}

    // MARK: - Public

    /// Автоопределение формата ввода и разбор.
    func resolve(_ input: String) async -> ImportResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure("Пустой ввод")
        }

        // 1) Одиночная VPN-ссылка
        if trimmed.hasPrefix("vless://") || trimmed.hasPrefix("vmess://") {
            if let config = VPNConfigurationService.shared.parse(trimmed) {
                return .single(config)
            }
            return .failure("Не удалось разобрать VPN-ссылку")
        }

        // 2) HTTP(S)-подписка
        if let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https" {
            do {
                let servers = try await fetch(trimmed)
                if servers.isEmpty {
                    return .failure("В подписке не найдено поддерживаемых серверов (VLESS/VMess)")
                }
                return .servers(servers)
            } catch {
                return .failure(error.localizedDescription)
            }
        }

        // 3) Возможно — base64-блок (например, вставили декодированную подписку целиком)
        let parsed = parseBody(trimmed)
        if parsed.isEmpty {
            return .failure("Неподдерживаемый формат. Поддерживаются: VLESS, VMess или ссылка на подписку (https)")
        }
        return .servers(parsed)
    }

    /// Загрузка подписки по URL. Шлём «клиентский» User-Agent: многие серверы
    /// возвращают 502 на дефолтные/пустые UA и 200 — на UA вида `v2rayNG/...`.
    func fetch(_ urlString: String) async throws -> [VPNConfiguration] {
        guard let url = URL(string: urlString) else {
            throw SubscriptionError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue("v2rayNG/1.8.25 (Android 14; Scale 2.1)", forHTTPHeaderField: "User-Agent")
        request.setValue("text/plain, */*", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw SubscriptionError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw SubscriptionError.httpError(http.statusCode)
        }

        guard let body = String(data: data, encoding: .utf8) else {
            throw SubscriptionError.invalidEncoding
        }

        return parseBody(body)
    }

    /// Разбор тела подписки: пробуем base64 целиком → иначе считаем plain-text списком.
    func parseBody(_ body: String) -> [VPNConfiguration] {
        let candidates = decodeCandidates(body)
        for candidate in candidates {
            if candidate.contains("://") {
                return parseLinks(from: candidate)
            }
        }
        // Если base64 не подошёл — работаем с исходным телом как с plain-text.
        return parseLinks(from: body)
    }

    // MARK: - Private

    /// Разбивает текст на строки и парсит каждую непустую VPN-ссылку.
    private func parseLinks(from text: String) -> [VPNConfiguration] {
        var result: [VPNConfiguration] = []
        // Перенос может быть любым: \n, \r\n, \r, либо даже пробелом.
        let lines = text
            .components(separatedBy: .newlines)
            .flatMap { $0.components(separatedBy: " ") }

        let parser = VPNConfigurationService.shared
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("vless://") || trimmed.hasPrefix("vmess://") else { continue }
            if let config = parser.parse(trimmed) {
                result.append(config)
            }
        }
        return result
    }

    /// Возвращает возможные декодирования base64 (с разным выравниванием padding).
    private func decodeCandidates(_ body: String) -> [String] {
        let cleaned = body
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()

        var candidates: [String] = []
        // Стандартное декодирование
        if let data = Data(base64Encoded: cleaned),
           let str = String(data: data, encoding: .utf8) {
            candidates.append(str)
        }
        // С дополнением padding до кратного 4 (некоторые подписки без `=`)
        let paddingNeeded = -cleaned.count % 4
        if paddingNeeded > 0 {
            let padded = cleaned + String(repeating: "=", count: paddingNeeded)
            if padded != cleaned,
               let data = Data(base64Encoded: padded),
               let str = String(data: data, encoding: .utf8) {
                candidates.append(str)
            }
        }
        // URL-safe base64: `-`/`_` → `+`/`/`
        let standard = cleaned
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if standard != cleaned {
            let paddedNeeded2 = -standard.count % 4
            let final = paddedNeeded2 > 0 ? standard + String(repeating: "=", count: paddedNeeded2) : standard
            if let data = Data(base64Encoded: final),
               let str = String(data: data, encoding: .utf8) {
                candidates.append(str)
            }
        }
        return candidates
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case invalidEncoding

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL подписки"
        case .invalidResponse:
            return "Некорректный ответ сервера подписки"
        case .httpError(let code):
            return "Сервер подписки вернул HTTP \(code)"
        case .invalidEncoding:
            return "Не удалось прочитать ответ подписки (кодировка)"
        }
    }
}
