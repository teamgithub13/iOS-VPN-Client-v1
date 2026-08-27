import Foundation
import NetworkExtension
import Combine
import os

enum VPNConnectionStatus {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case error(String)
}

class VPNConnectionService: ObservableObject {

    static let shared = VPNConnectionService()

    /// Логгер для отладки VPN-подключения. Виден в Console.app даже в TestFlight/Release сборках.
    /// Фильтр в Console.app: subsystem = "com.gooseberry.colander" ИЛИ "VPNConnection".
    private let logger = Logger(subsystem: "com.gooseberry.colander", category: "VPNConnection")

    @Published var connectionStatus: VPNConnectionStatus = .disconnected
    @Published var currentConfiguration: VPNConfiguration?
    
    private var vpnManager: NEVPNManager?
    private var packetTunnelProvider: NETunnelProviderManager?
    private let vpnConfigurationKey = "com.fastvpn.configuration"
    private let appGroupIdentifier = "group.com.gooseberry.colander"
    private let tunnelProviderBundleIdentifier = "com.gooseberry.colander.tunnel"

    private init() {
        loadVPNManager()
    }
    
    /// Загружает VPN менеджер
    private func loadVPNManager(completion: (() -> Void)? = nil) {
        // Для PacketTunnelProvider используем NETunnelProviderManager
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }

            if let error = error {
                logger.error("loadAllFromPreferences failed: \(error.localizedDescription, privacy: .public)")
                DispatchQueue.main.async {
                    self.connectionStatus = .error(error.localizedDescription)
                }
                completion?()
                return
            }

            // Ищем существующий менеджер или создаем новый
            if let manager = managers?.first {
                self.packetTunnelProvider = manager
                logger.info("Existing VPN manager found")
            } else {
                self.packetTunnelProvider = NETunnelProviderManager()
                logger.info("New VPN manager created")
            }

            self.observeVPNStatus()
            completion?()
        }
    }

    /// Настраивает VPN менеджер в зависимости от типа протокола и сохраняет конфигурацию.
    private func setupVPNManager(completion: @escaping (Error?) -> Void) {
        guard let manager = packetTunnelProvider,
              let config = currentConfiguration else {
            logger.warning("setupVPNManager: manager or configuration is missing")
            completion(NSError(domain: "VPNConnectionService", code: 10,
                               userInfo: [NSLocalizedDescriptionKey: "No configuration to save"]))
            return
        }

        // Декодируем remark из URL-encoding (в подписках часто содержит %-escaping эмодзи/кириллицы),
        // иначе в настройках iOS будет виден сырой текст вида %F0%9F%87%А9...
        let displayName = config.remark?.removingPercentEncoding ?? config.remark ?? "VPN"
        manager.localizedDescription = displayName.isEmpty ? "VPN" : displayName
        manager.isEnabled = true

        // Сохраняем конфигурацию в App Group для передачи в PacketTunnelProvider
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
           let configData = try? JSONEncoder().encode(config) {
            sharedDefaults.set(configData, forKey: vpnConfigurationKey)
            sharedDefaults.synchronize()
        }

        // Настраиваем протокол через PacketTunnelProvider для всех типов
        setupPacketTunnelProtocol(config, manager: manager, completion: completion)
    }
    
    /// Настраивает протокол через PacketTunnelProvider
    private func setupPacketTunnelProtocol(_ config: VPNConfiguration, manager: NETunnelProviderManager, completion: @escaping (Error?) -> Void) {
        // Создаем протокол для PacketTunnelProvider
        let protocolConfiguration = NETunnelProviderProtocol()
        protocolConfiguration.providerBundleIdentifier = tunnelProviderBundleIdentifier
        protocolConfiguration.serverAddress = config.address

        // Сохраняем дополнительные параметры в providerConfiguration для передачи в extension
        var providerConfiguration: [String: Any] = [:]
        providerConfiguration["protocolType"] = config.protocolType.rawValue
        providerConfiguration["address"] = config.address
        providerConfiguration["port"] = config.port

        // Добавляем специфичные параметры для VLESS/VMess
        if config.protocolType == .vless || config.protocolType == .vmess {
            if let sourceURL = config.sourceURL { providerConfiguration["sourceURL"] = sourceURL }
            if let uuid = config.uuid { providerConfiguration["uuid"] = uuid }
            if let security = config.security { providerConfiguration["security"] = security }
            if let sni = config.sni { providerConfiguration["sni"] = sni }
            if let alpn = config.alpn { providerConfiguration["alpn"] = alpn }
            if let type = config.type { providerConfiguration["type"] = type }
            if let flow = config.flow { providerConfiguration["flow"] = flow }
        }

        protocolConfiguration.providerConfiguration = providerConfiguration
        manager.protocolConfiguration = protocolConfiguration

        saveVPNConfiguration(manager, completion: completion)
    }

    /// Сохраняет VPN конфигурацию и перезагружает менеджер (iOS требует loadFromPreferences после save).
    private func saveVPNConfiguration(_ manager: NETunnelProviderManager, completion: @escaping (Error?) -> Void) {
        manager.saveToPreferences { [weak self] error in
            guard let self = self else {
                completion(error)
                return
            }
            if let error = error {
                self.logger.error("saveToPreferences failed: \(error.localizedDescription, privacy: .public)")
                DispatchQueue.main.async {
                    self.connectionStatus = .error(error.localizedDescription)
                }
                completion(error)
                return
            }
            self.logger.notice("VPN configuration saved")
            // iOS требует loadFromPreferences после save перед startVPNTunnel
            manager.loadFromPreferences { loadError in
                if let loadError = loadError {
                    self.logger.error("loadFromPreferences failed: \(loadError.localizedDescription, privacy: .public)")
                } else {
                    self.logger.notice("Manager reloaded after saving")
                }
                completion(loadError)
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

        let status = manager.connection.status
        logger.notice("VPN status changed: \(status.rawValue)")

        DispatchQueue.main.async {
            switch status {
            case .connected:
                self.connectionStatus = .connected
            case .connecting:
                self.connectionStatus = .connecting
            case .disconnecting:
                self.connectionStatus = .disconnecting
            case .disconnected:
                self.connectionStatus = .disconnected
            case .invalid:
                self.connectionStatus = .error("Invalid VPN configuration")
            case .reasserting:
                self.connectionStatus = .connecting
            @unknown default:
                self.connectionStatus = .disconnected
            }
        }
    }
    
    /// Устанавливает конфигурацию VPN из URL (поддерживает VLESS, VMess)
    func setConfiguration(from urlString: String) -> Bool {
        guard let config = VPNConfigurationService.shared.parse(urlString) else {
            connectionStatus = .error("Invalid VPN URL format")
            return false
        }

        setSelectedConfiguration(config)
        return true
    }

    /// Устанавливает уже разобранную конфигурацию (например, выбранную из списка серверов подписки).
    /// `save: false` — только запомнить (используется при переключении сервера: reconnect()
    /// сам сохранит конфигурацию перед стартом, двойное сохранение даёт NEVPNError.configurationStale).
    func setSelectedConfiguration(_ config: VPNConfiguration, save: Bool = true) {
        currentConfiguration = config
        logger.notice("Configuration set: \(config.address, privacy: .public):\(config.port)")

        guard save else { return }

        // Сохраняем конфигурацию (без запуска). Если менеджер ещё не загружен — загрузим и сохраним.
        if packetTunnelProvider == nil {
            loadVPNManager { [weak self] in
                self?.setupVPNManager { _ in }
            }
        } else {
            setupVPNManager { _ in }
        }
    }

    /// Устанавливает конфигурацию VPN из VLESS URL (legacy метод для обратной совместимости)
    func setConfigurationVLESS(from vlessURL: String) -> Bool {
        return setConfiguration(from: vlessURL)
    }

    /// Переподключение к текущей выбранной конфигурации.
    /// iOS требует остановить активный туннель перед применением новой конфигурации,
    /// иначе смена сервера не сработает (туннель останется на старом).
    func reconnect() {
        guard let manager = packetTunnelProvider else {
            connect()
            return
        }
        logger.notice("reconnect: stopping current tunnel before applying new config")
        manager.connection.stopVPNTunnel()
        DispatchQueue.main.async {
            self.connectionStatus = .disconnecting
        }
        // Ждём фактической остановки туннеля (статус .disconnected).
        // Фиксированная задержка ненадёжна: старт до реальной остановки даёт
        // NEVPNError.configurationStale.
        waitForTunnelStop(manager: manager) { [weak self] in
            self?.connect()
        }
    }

    /// Поллинг статуса туннеля до .disconnected/.invalid, максимум ~3с.
    private func waitForTunnelStop(manager: NETunnelProviderManager, completion: @escaping () -> Void) {
        var attemptsLeft = 15 // 15 × 0.2с = 3с максимум
        func check() {
            let status = manager.connection.status
            if status == .disconnected || status == .invalid {
                completion()
                return
            }
            attemptsLeft -= 1
            if attemptsLeft <= 0 {
                logger.warning("waitForTunnelStop: timeout, proceeding anyway")
                completion()
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { check() }
        }
        check()
    }

    /// Подключается к VPN.
    /// Самодостаточный flow: убеждается, что менеджер загружен и конфигурация сохранена,
    /// и только потом стартует туннель. Устраняет race condition (saveToPreferences → startVPNTunnel).
    func connect() {
        DispatchQueue.main.async { self.connectionStatus = .connecting }
        logger.notice("connect: starting connection flow...")

        // Если менеджер ещё не загружен — загрузить и повторить connect
        guard let manager = packetTunnelProvider else {
            logger.info("packetTunnelProvider == nil, loading manager and retrying connect...")
            loadVPNManager { [weak self] in
                self?.connect()
            }
            return
        }

        guard currentConfiguration != nil else {
            logger.warning("No configuration to connect")
            DispatchQueue.main.async {
                self.connectionStatus = .error("VPN configuration is not set")
            }
            return
        }

        // Сохранить конфигурацию → стартовать туннель
        setupVPNManager { [weak self] error in
            guard let self = self else { return }
            guard error == nil else {
                logger.error("Failed to save configuration before starting")
                return
            }
            do {
                try manager.connection.startVPNTunnel(options: nil)
                logger.notice("startVPNTunnel called successfully")
            } catch {
                let nsError = error as NSError
                logger.error("startVPNTunnel failed: \(nsError.domain, privacy: .public) code=\(nsError.code)")

                // configurationStale: менеджер устарел (гонка сохранений / система не успела).
                // Перезагружаем менеджеры из preferences и пробуем подключиться ещё раз.
                if nsError.domain == "NEVPNErrorDomain",
                   nsError.code == NEVPNError.configurationStale.rawValue {
                    self.recoverFromStaleConfiguration()
                    return
                }

                DispatchQueue.main.async {
                    self.connectionStatus = .error("Connection error: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Восстановление после NEVPNError.configurationStale:
    /// перезагружаем VPN-менеджеры из системных preferences и повторяем подключение (один раз).
    private var isRecoveringFromStaleConfig = false

    private func recoverFromStaleConfiguration() {
        guard !isRecoveringFromStaleConfig else {
            logger.warning("recoverFromStaleConfiguration: already recovering, skip")
            DispatchQueue.main.async {
                self.connectionStatus = .disconnected
            }
            return
        }
        isRecoveringFromStaleConfig = true
        logger.notice("recoverFromStaleConfiguration: reloading managers and retrying")

        loadVPNManager { [weak self] in
            guard let self else { return }
            self.isRecoveringFromStaleConfig = false
            self.connect()
        }
    }

    /// Отключается от VPN
    func disconnect() {
        guard let manager = packetTunnelProvider else { return }
        logger.notice("disconnect")
        manager.connection.stopVPNTunnel()
        DispatchQueue.main.async { self.connectionStatus = .disconnecting }
    }

    /// Полная очистка: отключить туннель, удалить VPN-профиль из системных настроек,
    /// сбросить текущую конфигурацию.
    func clearConfiguration() {
        currentConfiguration = nil
        logger.notice("clearConfiguration: removing VPN profile")

        guard let manager = packetTunnelProvider else {
            DispatchQueue.main.async { self.connectionStatus = .disconnected }
            return
        }

        if manager.connection.status == .connected
            || manager.connection.status == .connecting
            || manager.connection.status == .reasserting {
            manager.connection.stopVPNTunnel()
        }

        manager.removeFromPreferences { [weak self] error in
            if let error = error {
                self?.logger.error("removeFromPreferences failed: \(error.localizedDescription, privacy: .public)")
            } else {
                self?.logger.notice("VPN profile removed from preferences")
            }
        }

        packetTunnelProvider = nil
        DispatchQueue.main.async { self.connectionStatus = .disconnected }
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

    /// Запрашивает статистику трафика у PacketTunnelProvider через IPC.
    /// Ответ — 2 × UInt32 (received, sent). Возвращает `0, 0`, если туннель не запущен.
    func requestTrafficStats(completion: @escaping (_ received: UInt64, _ sent: UInt64) -> Void) {
        guard let manager = packetTunnelProvider,
              let session = manager.connection as? NETunnelProviderSession else {
            logger.warning("requestTrafficStats: session or manager is missing")
            completion(0, 0)
            return
        }

        do {
            // Пустое сообщение = команда «дай статистику»
            try session.sendProviderMessage(Data()) { [weak self] data in
                guard let data = data, data.count >= 8 else {
                    self?.logger.warning("requestTrafficStats: empty or short tunnel response (data.count=\(data?.count ?? -1))")
                    completion(0, 0)
                    return
                }
                let received = data.withUnsafeBytes { $0.load(as: UInt32.self) }
                let sent = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self) }
                self?.logger.notice("requestTrafficStats: received=\(received), sent=\(sent)")
                completion(UInt64(received), UInt64(sent))
            }
        } catch {
            logger.error("requestTrafficStats: sendProviderMessage error: \(error.localizedDescription, privacy: .public)")
            completion(0, 0)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
