import Foundation
import Combine
import SwiftUI

class ServiceVPN1ViewModel: ObservableObject {

    @Published var isConnected: Bool = false
    @Published var connectionStatus: VPNConnectionStatus = .disconnected
    @Published var receivedBytes: Int64 = 0
    @Published var sentBytes: Int64 = 0
    @Published var connectionTime: TimeInterval = 0
    @Published var errorMessage: String?
    /// Триггер нативного alert при ошибке подключения
    @Published var showErrorAlert: Bool = false

    /// Список серверов (из подписки или одиночной ссылки)
    @Published var servers: [VPNConfiguration] = []
    /// Индекс выбранного сервера
    @Published var selectedIndex: Int?
    /// Идёт загрузка/разбор подписки
    @Published var isLoading: Bool = false

    private let vpnService = VPNConnectionService.shared
    private let repository = ServerRepository.shared
    private var cancellables = Set<AnyCancellable>()
    private var connectionTimer: Timer?
    private var startTime: Date?

    init() {
        setupObservers()
        loadSavedState()
    }

    // MARK: - State

    private func loadSavedState() {
        servers = repository.loadServers()
        if let savedIndex = repository.loadSelectedIndex(), savedIndex < servers.count {
            selectedIndex = savedIndex
            // Восстанавливаем выбранную конфигурацию в VPN-сервисе
            vpnService.setSelectedConfiguration(servers[savedIndex])
        }
    }

    private func setupObservers() {
        // Подписываемся на изменения статуса VPN
        vpnService.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.connectionStatus = status
                self?.updateConnectionState(status)
            }
            .store(in: &cancellables)
    }

    private func updateConnectionState(_ status: VPNConnectionStatus) {
        switch status {
        case .connected:
            isConnected = true
            startTime = Date()
            startConnectionTimer()
            errorMessage = nil
        case .connecting:
            isConnected = false
            errorMessage = nil
        case .disconnected:
            isConnected = false
            stopConnectionTimer()
            connectionTime = 0
            receivedBytes = 0
            sentBytes = 0
            errorMessage = nil
        case .disconnecting:
            isConnected = false
            errorMessage = nil
        case .error(let message):
            isConnected = false
            stopConnectionTimer()
            connectionTime = 0
            receivedBytes = 0
            sentBytes = 0
            errorMessage = message
            showErrorAlert = true
        }
    }

    private func startConnectionTimer() {
        stopConnectionTimer()
        connectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.connectionTime = Date().timeIntervalSince(startTime)
            // Запрашиваем статистику трафика у туннеля
            self.vpnService.requestTrafficStats { received, sent in
                DispatchQueue.main.async {
                    self.receivedBytes = Int64(received)
                    self.sentBytes = Int64(sent)
                }
            }
        }
    }

    private func stopConnectionTimer() {
        connectionTimer?.invalidate()
        connectionTimer = nil
        startTime = nil
    }

    // MARK: - Actions

    /// Замыкание для открытия SFSafariViewController (инъектируется из ViewController)
    var openSafari: ((URL) -> Void)?

    var openSupport: (() -> Void)?

    func onTapGetKey() {
        guard let url = URL(string: "https://www.google.com") else { return }
        openSafari?(url)
    }

    func onTapSupport() {
        openSupport?()
    }

    // MARK: - VPN

    /// Переключает состояние VPN подключения
    func toggleVPN() {
        // Если конфигурация не выбрана — выбираем первый доступный сервер
        if vpnService.currentConfiguration == nil {
            if !servers.isEmpty {
                select(at: 0)
            } else {
                // Фолбэк: пример из запроса (для обратной совместимости)
                let exampleURL = "vless://33e24a0e-71e5-4fed-9e24-29d8364a65cd@83.143.113.229:443?security=reality&sni=www.bing.com&alpn=h2&fp=chrome&pbk=ckRcueERkPqqjZABwxqni_J_Nbb70Q6k5fEEUAjoImw&type=tcp&flow=xtls-rprx-vision&encryption=none#avovpn.com-5476184-4036300"
                _ = vpnService.setConfiguration(from: exampleURL)
            }
        }

        vpnService.toggleConnection()
    }

    // MARK: - Import / Subscription

    /// Импорт конфигурации: одиночная ссылка или подписка (https). Автоопределение.
    /// `customName` (если задано) переопределяет отображаемое имя одиночной конфигурации;
    /// для подписки (несколько серверов) игнорируется — используются их собственные remark.
    func importConfiguration(from input: String, customName: String? = nil) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Пустой ввод"
            return
        }

        // Пользовательское имя триммим; пустое считаем как «не задано»
        let name = customName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveName = (name?.isEmpty == false) ? name : nil

        isLoading = true
        errorMessage = nil

        Task { [weak self] in
            guard let self = self else { return }
            let result = await SubscriptionService.shared.resolve(trimmed)
            await MainActor.run {
                self.isLoading = false
                self.applyImportResult(result, sourceURL: trimmed, customName: effectiveName)
            }
        }
    }

    private func applyImportResult(_ result: ImportResult, sourceURL: String, customName: String?) {
        switch result {
        case .single(var config):
            // Переопределяем имя пользовательским, если оно задано
            if let customName = customName {
                config.remark = customName
            }
            servers = [config]
            repository.saveServers(servers)
            repository.saveSubscriptionURL(nil)
            select(at: 0)
            errorMessage = nil
        case .servers(let list) where !list.isEmpty:
            servers = list
            repository.saveServers(servers)
            // Сохраняем URL подписки только для http(s)-источников
            if sourceURL.hasPrefix("http://") || sourceURL.hasPrefix("https://") {
                repository.saveSubscriptionURL(sourceURL)
            } else {
                repository.saveSubscriptionURL(nil)
            }
            select(at: 0)
            errorMessage = nil
        case .servers:
            errorMessage = "В подписке не найдено поддерживаемых серверов (VLESS/VMess)"
        case .failure(let message):
            errorMessage = message
        }
    }

    /// Выбор сервера из списка
    func select(at index: Int) {
        guard servers.indices.contains(index) else { return }
        selectedIndex = index
        repository.saveSelectedIndex(index)
        let config = servers[index]
        vpnService.setSelectedConfiguration(config)
    }

    /// Обновление подписки по сохранённому URL
    func refreshSubscription() {
        guard let url = repository.loadSubscriptionURL() else {
            errorMessage = "URL подписки не сохранён"
            return
        }
        importConfiguration(from: url)
    }

    /// Есть ли сохранённая подписка для обновления
    var hasSavedSubscription: Bool {
        repository.loadSubscriptionURL() != nil
    }

    // MARK: - Formatting

    /// Форматирует время подключения в строку MM:SS
    func formattedConnectionTime() -> String {
        let minutes = Int(connectionTime) / 60
        let seconds = Int(connectionTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Форматирует байты в читаемый формат
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }

    /// URL-декодирует remark (в подписках часто содержит %-escaping эмодзи/кириллицы)
    func decodedRemark(_ remark: String?) -> String {
        guard let remark = remark else { return "VPN Server" }
        return remark.removingPercentEncoding ?? remark
    }

    deinit {
        stopConnectionTimer()
        cancellables.removeAll()
    }
}
