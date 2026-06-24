import NetworkExtension
import Foundation

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private var tunnelInterface: String?
    private var configuration: VPNConfiguration?
    private var wireGuardTunnel: WireGuardTunnel?
    private var v2RayTunnel: V2RayTunnel?
    private var shadowsocksTunnel: ShadowsocksTunnel?
    
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
        case .wireguard:
            startWireGuardTunnel(config: config, completionHandler: completionHandler)
        case .vless, .vmess:
            startV2RayTunnel(config: config, completionHandler: completionHandler)
        case .shadowsocks, .shadowsocksR:
            startShadowsocksTunnel(config: config, completionHandler: completionHandler)
        case .unknown:
            completionHandler(NSError(domain: "PacketTunnelProvider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Неизвестный тип протокола"]))
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        // Останавливаем все подключения
        wireGuardTunnel?.stop {
            // no-op
        }
        v2RayTunnel?.stop()
        shadowsocksTunnel?.stop()
        
        wireGuardTunnel = nil
        v2RayTunnel = nil
        shadowsocksTunnel = nil
        configuration = nil
        
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Обработка сообщений от основного приложения
        // Можно использовать для получения статистики, изменения настроек и т.д.
        completionHandler?(nil)
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        // Обработка перехода устройства в режим сна
        completionHandler()
    }
    
    override func wake() {
        // Обработка пробуждения устройства
    }
    
    // MARK: - WireGuard Implementation
    
    private func startWireGuardTunnel(config: VPNConfiguration, completionHandler: @escaping (Error?) -> Void) {
        let tunnel = WireGuardTunnel(config: config, provider: self)
        wireGuardTunnel = tunnel

        tunnel.start { error in
            completionHandler(error)
        }
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
    
    // MARK: - Shadowsocks Implementation
    
    private func startShadowsocksTunnel(config: VPNConfiguration, completionHandler: @escaping (Error?) -> Void) {
        let tunnel = ShadowsocksTunnel(config: config)
        shadowsocksTunnel = tunnel
        tunnel.start(packetFlow: packetFlow, completionHandler: completionHandler)
    }
}
