import Foundation

class VPNConfigurationService {

    static let shared = VPNConfigurationService()

    private init() {}

    /// Универсальный метод парсинга VPN конфигурации из URL
    func parse(_ urlString: String) -> VPNConfiguration? {
        guard let url = URL(string: urlString) else {
            return nil
        }

        let scheme = url.scheme?.lowercased() ?? ""

        switch scheme {
        case "vless":
            return parseVLESS(urlString)
        case "vmess":
            return parseVMess(urlString)
        default:
            // Попытка определить протокол по содержимому
            if urlString.contains("vless://") {
                return parseVLESS(urlString)
            } else if urlString.contains("vmess://") {
                return parseVMess(urlString)
            }
            return nil
        }
    }

    /// Парсит VLESS URL
    func parseVLESS(_ urlString: String) -> VPNConfiguration? {
        guard let url = URL(string: urlString),
              url.scheme == "vless" else {
            return nil
        }

        // Извлекаем UUID из userinfo
        guard let uuid = url.user else {
            return nil
        }

        // Извлекаем host и port
        guard let host = url.host else {
            return nil
        }
        let port = url.port ?? 443

        // Извлекаем remark из fragment
        let remark = url.fragment

        // Парсим query параметры
        var queryParams: [String: String] = [:]
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            for item in queryItems {
                queryParams[item.name] = item.value
            }
        }

        let security = queryParams["security"] ?? "none"
        let sni = queryParams["sni"]
        let alpn = queryParams["alpn"]
        let fingerprint = queryParams["fp"]
        let type = queryParams["type"] ?? "tcp"
        let flow = queryParams["flow"]
        let encryption = queryParams["encryption"] ?? "none"

        return VPNConfiguration(
            protocolType: .vless,
            sourceURL: urlString,
            address: host,
            port: port,
            remark: remark,
            uuid: uuid,
            security: security,
            sni: sni,
            alpn: alpn,
            fingerprint: fingerprint,
            type: type,
            flow: flow,
            encryption: encryption
        )
    }

    /// Парсит VMess URL
    func parseVMess(_ urlString: String) -> VPNConfiguration? {
        guard urlString.hasPrefix("vmess://") else {
            return nil
        }

        // Удаляем префикс vmess://
        let base64String = String(urlString.dropFirst(8))

        // Декодируем base64
        guard let decodedData = Data(base64Encoded: base64String),
              let jsonString = String(data: decodedData, encoding: .utf8),
              let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }

        guard let address = json["add"] as? String,
              let uuid = json["id"] as? String else {
            return nil
        }

        // Порт может быть строкой или числом
        let port: Int
        if let portString = json["port"] as? String {
            guard let portValue = Int(portString) else {
                return nil
            }
            port = portValue
        } else if let portNumber = json["port"] as? Int {
            port = portNumber
        } else {
            return nil
        }

        let remark = json["ps"] as? String
        let alterId = json["aid"] as? String
        let network = json["net"] as? String ?? "tcp"
        let tls = json["tls"] as? String
        let sni = json["sni"] as? String

        return VPNConfiguration(
            protocolType: .vmess,
            sourceURL: urlString,
            address: address,
            port: port,
            remark: remark,
            uuid: uuid,
            sni: sni, alterId: alterId != nil ? Int(alterId!) : nil,
            network: network,
            tls: tls
        )
    }

    /// Валидирует VPN URL
    func validate(_ urlString: String) -> Bool {
        return parse(urlString) != nil
    }

    // MARK: - Legacy методы для обратной совместимости

    /// Парсит VLESS URL (legacy метод)
    func parseVLESSURL(_ urlString: String) -> VPNConfiguration? {
        return parseVLESS(urlString)
    }

    /// Валидирует VLESS URL (legacy метод)
    func validateVLESSURL(_ urlString: String) -> Bool {
        return parseVLESS(urlString) != nil
    }
}
