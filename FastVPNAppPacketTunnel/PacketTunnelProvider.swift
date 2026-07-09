import NetworkExtension
import Foundation

class PacketTunnelProvider: NEPacketTunnelProvider {

    private var tunnelInterface: String?
    private var configuration: VPNConfiguration?
    private var v2RayTunnel: V2RayTunnel?

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Получаем конфигурацию из UserDefaults (переданную из основного приложения)
        guard let configData = UserDefaults(suiteName: "group.com.gooseberry.colander")?.data(forKey: "com.fastvpn.configuration"),
              let config = try? JSONDecoder().decode(VPNConfiguration.self, from: configData) else {
            completionHandler(NSError(domain: "PacketTunnelProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Конфигурация VPN не найдена"]))
            return
        }

        self.configuration = config

        // Настраиваем tunnel в зависимости от типа протокола
        switch config.protocolType {
        case .vless, .vmess:
            startV2RayTunnel(config: config, completionHandler: completionHandler)
        case .unknown:
            completionHandler(NSError(domain: "PacketTunnelProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Неизвестный тип протокола"]))
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Останавливаем подключение
        v2RayTunnel?.stop()

        v2RayTunnel = nil
        configuration = nil

        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // IPC-канал от основного приложения. Пустое сообщение или "stats" — запрос статистики.
        let command = String(data: messageData, encoding: .utf8)
        guard messageData.isEmpty || command == "stats" else {
            completionHandler?(nil)
            return
        }

        Task { [weak self] in
            guard let self = self else {
                completionHandler?(nil)
                return
            }
            let stats = await self.v2RayTunnel?.bytesTransferred()
            let received: UInt32 = stats?.received ?? 0
            let sent: UInt32 = stats?.sent ?? 0

            // Бинарный формат: 2 × UInt32 little-endian (8 байт)
            var payload = [received, sent]
            let data = withUnsafeBytes(of: &payload) { Data($0) }
            completionHandler?(data)
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        // Обработка перехода устройства в режим сна
        completionHandler()
    }

    override func wake() {
        // Обработка пробуждения устройства
    }

    // MARK: - V2Ray (VLESS/VMess) Implementation

    private func startV2RayTunnel(config: VPNConfiguration, completionHandler: @escaping (Error?) -> Void) {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: config.address)

        // Настройка IPv4
        let ipv4Settings = NEIPv4Settings(addresses: ["10.0.0.2"], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4Settings

        // Настройка DNS
        let dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4"])
        settings.dnsSettings = dnsSettings

        // Применяем настройки сети
        setTunnelNetworkSettings(settings) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                completionHandler(error)
                return
            }

            // Создаем и запускаем V2Ray туннель
            let tunnel = V2RayTunnel(config: config)
            self.v2RayTunnel = tunnel

            tunnel.start(packetFlow: self.packetFlow) { error in
                if let error = error {
                    completionHandler(error)
                } else {
                    // Туннель успешно запущен
                    completionHandler(nil)
                }
            }
        }
    }
}
