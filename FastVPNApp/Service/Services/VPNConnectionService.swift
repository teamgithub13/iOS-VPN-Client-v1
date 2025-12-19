import Foundation
import NetworkExtension
import Combine

enum VPNConnectionStatus {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case error(String)
}

class VPNConnectionService: ObservableObject {
    
    static let shared = VPNConnectionService()
    
    @Published var connectionStatus: VPNConnectionStatus = .disconnected
    @Published var currentConfiguration: VPNConfiguration?
    
    private var vpnManager: NEVPNManager?
    private var packetTunnelProvider: NETunnelProviderManager?
    private let vpnConfigurationKey = "com.fastvpn.configuration"
    private let appGroupIdentifier = "group.com.asdf.FastVPNApp"
    private let tunnelProviderBundleIdentifier = "com.asdf.FastVPNApp.PacketTunnel"
    
    private init() {
        loadVPNManager()
    }
    
    /// Загружает VPN менеджер
    private func loadVPNManager() {
        // Для PacketTunnelProvider используем NETunnelProviderManager
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Ошибка загрузки VPN менеджера: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.connectionStatus = .error(error.localizedDescription)
                }
                return
            }
            
            // Ищем существующий менеджер или создаем новый
            if let manager = managers?.first {
                self.packetTunnelProvider = manager
            } else {
                self.packetTunnelProvider = NETunnelProviderManager()
            }
            
            self.setupVPNManager()
            self.observeVPNStatus()
        }
    }
    
    /// Настраивает VPN менеджер в зависимости от типа протокола
    private func setupVPNManager() {
        guard let manager = packetTunnelProvider,
              let config = currentConfiguration else { return }
        
        manager.localizedDescription = config.remark ?? "FastVPN - \(config.protocolType.displayName)"
        manager.isEnabled = true
        
        // Сохраняем конфигурацию в App Group для передачи в PacketTunnelProvider
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
           let configData = try? JSONEncoder().encode(config) {
            sharedDefaults.set(configData, forKey: vpnConfigurationKey)
            sharedDefaults.synchronize()
        }
        
        // Настраиваем протокол через PacketTunnelProvider для всех типов
        setupPacketTunnelProtocol(config, manager: manager)
    }
    
    /// Настраивает протокол через PacketTunnelProvider
    private func setupPacketTunnelProtocol(_ config: VPNConfiguration, manager: NETunnelProviderManager) {
        // Создаем протокол для PacketTunnelProvider
        let protocolConfiguration = NETunnelProviderProtocol()
        protocolConfiguration.providerBundleIdentifier = tunnelProviderBundleIdentifier
        protocolConfiguration.serverAddress = config.address
        
        // Сохраняем дополнительные параметры в providerConfiguration для передачи в extension
        var providerConfiguration: [String: Any] = [:]
        providerConfiguration["protocolType"] = config.protocolType.rawValue
        providerConfiguration["address"] = config.address
        providerConfiguration["port"] = config.port
        
        // Добавляем специфичные параметры для каждого протокола
        switch config.protocolType {
        case .vless, .vmess:
            if let uuid = config.uuid { providerConfiguration["uuid"] = uuid }
            if let security = config.security { providerConfiguration["security"] = security }
            if let sni = config.sni { providerConfiguration["sni"] = sni }
            if let alpn = config.alpn { providerConfiguration["alpn"] = alpn }
            if let type = config.type { providerConfiguration["type"] = type }
            if let flow = config.flow { providerConfiguration["flow"] = flow }
        case .shadowsocks, .shadowsocksR:
            if let method = config.method { providerConfiguration["method"] = method }
            if let password = config.password { providerConfiguration["password"] = password }
        case .wireguard:
            if let privateKey = config.privateKey { providerConfiguration["privateKey"] = privateKey }
            if let publicKey = config.publicKey { providerConfiguration["publicKey"] = publicKey }
            if let presharedKey = config.presharedKey { providerConfiguration["presharedKey"] = presharedKey }
            if let dns = config.dns { providerConfiguration["dns"] = dns }
            if let allowedIPs = config.allowedIPs { providerConfiguration["allowedIPs"] = allowedIPs }
        default:
            break
        }
        
        protocolConfiguration.providerConfiguration = providerConfiguration
        manager.protocolConfiguration = protocolConfiguration
        
        saveVPNConfiguration(manager)
    }
    
    /// Сохраняет VPN конфигурацию
    private func saveVPNConfiguration(_ manager: NETunnelProviderManager) {
        manager.saveToPreferences { [weak self] error in
            if let error = error {
                print("Ошибка сохранения VPN конфигурации: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.connectionStatus = .error(error.localizedDescription)
                }
            } else {
                print("VPN конфигурация успешно сохранена")
                // Перезагружаем менеджер после сохранения
                manager.loadFromPreferences { error in
                    if let error = error {
                        print("Ошибка загрузки после сохранения: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Получает сохраненную конфигурацию для PacketTunnelProvider
    func getConfigurationForPacketTunnel() -> VPNConfiguration? {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let configData = sharedDefaults.data(forKey: vpnConfigurationKey),
              let config = try? JSONDecoder().decode(VPNConfiguration.self, from: configData) else {
            return nil
        }
        return config
    }
    
    /// Наблюдает за статусом VPN подключения
    private func observeVPNStatus() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusChanged),
            name: .NEVPNStatusDidChange,
            object: nil
        )
    }
    
    @objc private func vpnStatusChanged() {
        guard let manager = packetTunnelProvider else { return }
        
        DispatchQueue.main.async {
            switch manager.connection.status {
            case .connected:
                self.connectionStatus = .connected
            case .connecting:
                self.connectionStatus = .connecting
            case .disconnecting:
                self.connectionStatus = .disconnecting
            case .disconnected:
                self.connectionStatus = .disconnected
            case .invalid:
                self.connectionStatus = .error("Недействительная конфигурация VPN")
            case .reasserting:
                self.connectionStatus = .connecting
            @unknown default:
                self.connectionStatus = .disconnected
            }
        }
    }
    
    /// Устанавливает конфигурацию VPN из URL (поддерживает VLESS, VMess, Shadowsocks, WireGuard)
    func setConfiguration(from urlString: String) -> Bool {
        guard let config = VPNConfigurationService.shared.parse(urlString) else {
            connectionStatus = .error("Неверный формат VPN URL")
            return false
        }
        
        currentConfiguration = config
        
        // Если менеджер еще не загружен, загружаем его
        if vpnManager == nil {
            loadVPNManager()
        } else {
            setupVPNManager()
        }
        
        return true
    }
    
    /// Устанавливает конфигурацию VPN из VLESS URL (legacy метод для обратной совместимости)
    func setConfigurationVLESS(from vlessURL: String) -> Bool {
        return setConfiguration(from: vlessURL)
    }
    
    /// Подключается к VPN
    func connect() {
        guard let manager = packetTunnelProvider else {
            loadVPNManager()
            return
        }
        
        guard currentConfiguration != nil else {
            connectionStatus = .error("Конфигурация VPN не установлена")
            return
        }
        
        do {
            try manager.connection.startVPNTunnel(options: nil)
            connectionStatus = .connecting
        } catch {
            connectionStatus = .error("Ошибка подключения: \(error.localizedDescription)")
        }
    }
    
    /// Отключается от VPN
    func disconnect() {
        guard let manager = packetTunnelProvider else { return }
        manager.connection.stopVPNTunnel()
        connectionStatus = .disconnecting
    }
    
    /// Переключает состояние подключения
    func toggleConnection() {
        switch connectionStatus {
        case .connected, .connecting:
            disconnect()
        case .disconnected, .disconnecting:
            connect()
        case .error:
            connect()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

