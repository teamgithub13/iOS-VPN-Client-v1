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
        case "ss":
            return parseShadowsocks(urlString)
        case "ssr":
            return parseShadowsocksR(urlString)
        case "wireguard", "wg":
            return parseWireGuard(urlString)
        default:
            // Попытка определить протокол по содержимому
            if urlString.contains("vless://") {
                return parseVLESS(urlString)
            } else if urlString.contains("vmess://") {
                return parseVMess(urlString)
            } else if urlString.contains("ss://") {
                return parseShadowsocks(urlString)
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
    
    /// Парсит Shadowsocks URL
    func parseShadowsocks(_ urlString: String) -> VPNConfiguration? {
        guard urlString.hasPrefix("ss://") else {
            return nil
        }
        
        let base64String = String(urlString.dropFirst(5))
        
        // Удаляем fragment если есть
        let parts = base64String.split(separator: "#", maxSplits: 1)
        let configPart = String(parts[0])
        let remark = parts.count > 1 ? String(parts[1]) : nil
        
        // Пробуем декодировать base64 (с учетом padding)
        var paddedBase64String = configPart
        // Добавляем padding если нужно
        let remainder = paddedBase64String.count % 4
        if remainder > 0 {
            paddedBase64String += String(repeating: "=", count: 4 - remainder)
        }
        
        if let decodedData = Data(base64Encoded: paddedBase64String),
           let decodedString = String(data: decodedData, encoding: .utf8) {
            // Формат: method:password@server:port
            return parseShadowsocksPlain(decodedString, remark: remark)
        }
        
        // Если не base64, пробуем парсить как обычный URL
        if let url = URL(string: "ss://\(configPart)") {
            return parseShadowsocksFromURL(url, remark: remark)
        }
        
        return nil
    }
    
    /// Парсит Shadowsocks из plain строки (method:password@server:port)
    private func parseShadowsocksPlain(_ plainString: String, remark: String?) -> VPNConfiguration? {
        // Формат: method:password@server:port
        guard let atIndex = plainString.firstIndex(of: "@") else {
            return nil
        }
        
        let credentials = String(plainString[..<atIndex])
        let serverPart = String(plainString[plainString.index(after: atIndex)...])
        
        // Парсим credentials (method:password)
        guard let colonIndex = credentials.firstIndex(of: ":") else {
            return nil
        }
        
        let method = String(credentials[..<colonIndex])
        let password = String(credentials[credentials.index(after: colonIndex)...])
        
        // Парсим server:port
        guard let portColonIndex = serverPart.lastIndex(of: ":") else {
            return nil
        }
        
        let address = String(serverPart[..<portColonIndex])
        guard let port = Int(String(serverPart[serverPart.index(after: portColonIndex)...])) else {
            return nil
        }
        
        return VPNConfiguration(
            protocolType: .shadowsocks,
            address: address,
            port: port,
            remark: remark,
            method: method,
            password: password
        )
    }
    
    /// Парсит Shadowsocks из URL
    private func parseShadowsocksFromURL(_ url: URL, remark: String?) -> VPNConfiguration? {
        guard let host = url.host else {
            return nil
        }
        
        let port = url.port ?? 8388
        
        // Парсим userinfo (method:password в base64)
        guard let userInfo = url.user,
              let decodedData = Data(base64Encoded: userInfo),
              let decodedString = String(data: decodedData, encoding: .utf8),
              let colonIndex = decodedString.firstIndex(of: ":") else {
            return nil
        }
        
        let method = String(decodedString[..<colonIndex])
        let password = String(decodedString[decodedString.index(after: colonIndex)...])
        
        return VPNConfiguration(
            protocolType: .shadowsocks,
            address: host,
            port: port,
            remark: remark ?? url.fragment,
            method: method,
            password: password
        )
    }
    
    /// Парсит ShadowsocksR URL
    func parseShadowsocksR(_ urlString: String) -> VPNConfiguration? {
        // ShadowsocksR формат: ssr://base64(server:port:protocol:method:obfs:base64(password)/?obfsparam=base64(obfsparam)&protoparam=base64(protoparam)&remarks=base64(remarks))
        guard urlString.hasPrefix("ssr://") else {
            return nil
        }
        
        let base64String = String(urlString.dropFirst(6))
        
        guard let decodedData = Data(base64Encoded: base64String),
              let decodedString = String(data: decodedData, encoding: .utf8) else {
            return nil
        }
        
        // Парсим формат: server:port:protocol:method:obfs:password/?params
        let parts = decodedString.split(separator: "/", maxSplits: 1)
        let mainPart = String(parts[0])
        let paramsPart = parts.count > 1 ? String(parts[1]) : nil
        
        let components = mainPart.split(separator: ":")
        guard components.count >= 6,
              let port = Int(components[1]) else {
            return nil
        }
        
        let address = String(components[0])
        let protocolType = String(components[2])
        let method = String(components[3])
        let obfs = String(components[4])
        
        // Пароль в base64
        let passwordBase64 = String(components[5])
        let password = String(data: Data(base64Encoded: passwordBase64) ?? Data(), encoding: .utf8) ?? ""
        
        // Парсим параметры из query
        var remark: String? = nil
        if let paramsPart = paramsPart,
           let paramsURL = URL(string: "ssr://?\(paramsPart)"),
           let queryItems = URLComponents(url: paramsURL, resolvingAgainstBaseURL: false)?.queryItems {
            for item in queryItems {
                if item.name == "remarks",
                   let value = item.value,
                   let decoded = Data(base64Encoded: value),
                   let decodedRemark = String(data: decoded, encoding: .utf8) {
                    remark = decodedRemark
                }
            }
        }
        
        return VPNConfiguration(
            protocolType: .shadowsocksR,
            address: address,
            port: port,
            remark: remark,
            method: method,
            password: password
        )
    }
    
    /// Парсит WireGuard URL или конфигурацию
    func parseWireGuard(_ urlString: String) -> VPNConfiguration? {
        // WireGuard может быть в формате wireguard://base64(config) или просто конфигурационный файл
        if urlString.hasPrefix("wireguard://") || urlString.hasPrefix("wg://") {
            let base64String = urlString.hasPrefix("wireguard://") 
                ? String(urlString.dropFirst(12))
                : String(urlString.dropFirst(3))
            
            guard let decodedData = Data(base64Encoded: base64String),
                  let configString = String(data: decodedData, encoding: .utf8) else {
                return nil
            }
            
            return parseWireGuardConfig(configString)
        } else {
            // Пробуем парсить как конфигурационный файл
            return parseWireGuardConfig(urlString)
        }
    }
    
    /// Парсит WireGuard конфигурационный файл
    private func parseWireGuardConfig(_ configString: String) -> VPNConfiguration? {
        var privateKey: String?
        var publicKey: String?
        var presharedKey: String?
        var interfaceAddress: String?
        var dns: String?
        var allowedIPs: String?
        var endpoint: String?
        var port: Int = 51820
        var remark: String?
        
        let lines = configString.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            if let equalIndex = trimmed.firstIndex(of: "=") {
                let key = String(trimmed[..<equalIndex]).trimmingCharacters(in: .whitespaces)
                let value = String(trimmed[trimmed.index(after: equalIndex)...]).trimmingCharacters(in: .whitespaces)
                
                switch key.lowercased() {
                case "privatekey":
                    privateKey = value
                case "publickey":
                    publicKey = value
                case "presharedkey":
                    presharedKey = value
                case "address":
                    interfaceAddress = value
                case "dns":
                    dns = value
                case "allowedips":
                    allowedIPs = value
                case "endpoint":
                    endpoint = value
                case "listenport":
                    port = Int(value) ?? 51820
                default:
                    break
                }
            }
        }
        
        // Парсим endpoint для получения адреса и порта
        var remoteAddress: String?
        var remotePort: Int = port

        if let endpoint = endpoint {
            let endpointParts = endpoint.split(separator: ":")
            if endpointParts.count >= 2,
               let endpointHost = endpointParts.first.map(String.init) {
                remoteAddress = endpointHost
                if let endpointPort = endpointParts.last.flatMap({ Int(String($0)) }) {
                    remotePort = endpointPort
                }
            } else {
                remoteAddress = endpoint
            }
        }

        guard let address = remoteAddress else {
            return nil
        }

        return VPNConfiguration(
            protocolType: .wireguard,
            address: address,
            port: remotePort,
            remark: remark,
            privateKey: privateKey,
            publicKey: publicKey,
            presharedKey: presharedKey,
            dns: dns,
            interfaceAddress: interfaceAddress,
            allowedIPs: allowedIPs,
            endpoint: endpoint
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
