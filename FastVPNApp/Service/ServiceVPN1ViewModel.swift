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
            // Сохраняем накопленный за сессию трафик в Proxy traffic volume (Statistics)
            StatisticsRepository.shared.addSessionTraffic(
                download: receivedBytes,
                upload: sentBytes
            )
            // Traffic volume directly — отдельная рандомная прибавка
            StatisticsRepository.shared.addRandomSessionTraffic()
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
        startTime = Date()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.connectionTime = Date().timeIntervalSince(startTime)

            // Плавная симуляция трафика каждую секунду (небольшие прибавления).
            // ~10–200 КБ/с received, ~5–80 КБ/с sent — значения «живые» и реалистичные.
            self.receivedBytes += Int64.random(in: 10_000...200_000)
            self.sentBytes += Int64.random(in: 5_000...80_000)
        }
        // Добавляем в RunLoop с .common mode — таймер не «замрёт» при скролле/жестах
        RunLoop.main.add(timer, forMode: .common)
        connectionTimer = timer
    }

    private func stopConnectionTimer() {
        connectionTimer?.invalidate()
        connectionTimer = nil
        startTime = nil
    }

    // MARK: - Actions

    var openSupport: (() -> Void)?

    func onTapGetKey() {
        guard requireInternet() else { return }
        // URL из Remote Config (app_get_key_btn_url). Открываем во внешнем браузере по умолчанию.
        let fallback = "https://www.google.com/"
        let urlString = RemoteConfigService.shared.string(
            forKey: RemoteConfigService.getKeyBtnURLKey,
            defaultValue: fallback
        ) ?? fallback
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    func onTapSupport() {
        openSupport?()
    }

    // MARK: - VPN

    /// Переключает состояние VPN подключения
    func toggleVPN() {
        if case .connected = connectionStatus {
            vpnService.toggleConnection()
            return
        }
        if case .connecting = connectionStatus {
            vpnService.toggleConnection()
            return
        }

        guard requireInternet() else { return }

        // Гарантируем, что конфигурация выбрана.
        // Если в сервисе её нет — берём выбранный/первый сервер из списка.
        // Без добавленных серверов подключение невозможно.
        if vpnService.currentConfiguration == nil {
            guard !servers.isEmpty else {
                errorMessage = "Add a VPN configuration first"
                showErrorAlert = true
                return
            }
            let index = selectedIndex ?? 0
            select(at: min(index, servers.count - 1))
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
            errorMessage = "Empty input"
            return
        }

        if let url = URL(string: trimmed),
           let scheme = url.scheme?.lowercased(),
           ["http", "https"].contains(scheme),
           !requireInternet() {
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
            errorMessage = "No supported servers found in the subscription (VLESS/VMess)"
        case .failure(let message):
            errorMessage = message
        }
    }

    /// Выбор сервера из списка.
    /// Если VPN уже подключен к другому серверу — переподключаемся на новый.
    func select(at index: Int) {
        guard servers.indices.contains(index) else { return }
        let wasConnected = isConnected
        let previousIndex = selectedIndex
        selectedIndex = index
        repository.saveSelectedIndex(index)
        let config = servers[index]

        if wasConnected && previousIndex != index {
            // Переключение сервера: только запоминаем конфиг (save: false) и переподключаемся.
            // reconnect() сам сохранит конфигурацию перед стартом — двойное сохранение
            // приводило к NEVPNError.configurationStale.
            vpnService.setSelectedConfiguration(config, save: false)
            vpnService.reconnect()
        } else {
            vpnService.setSelectedConfiguration(config)
        }
    }

    /// Обновление подписки по сохранённому URL
    func refreshSubscription() {
        guard requireInternet() else { return }
        guard let url = repository.loadSubscriptionURL() else {
            errorMessage = "Subscription URL is not saved"
            return
        }
        importConfiguration(from: url)
    }

    /// Полное удаление текущей конфигурации/подписки:
    /// отключаем VPN, чистим список серверов, выбранный индекс, URL подписки
    /// и VPN-профиль из системных настроек.
    func deleteConfiguration() {
        vpnService.clearConfiguration()
        servers = []
        selectedIndex = nil
        repository.clearServers()
        repository.saveSelectedIndex(nil)
        repository.saveSubscriptionURL(nil)
        errorMessage = nil
    }

    /// Есть ли сохранённая подписка для обновления
    var hasSavedSubscription: Bool {
        repository.loadSubscriptionURL() != nil
    }

    @discardableResult
    private func requireInternet() -> Bool {
        guard InternetAvailabilityService.shared.isConnected else {
            InternetAvailabilityService.shared.showOfflineAlert()
            return false
        }
        return true
    }

    // MARK: - Formatting

    /// Форматирует время подключения в строку MM:SS
    func formattedConnectionTime() -> String {
        let minutes = Int(connectionTime) / 60
        let seconds = Int(connectionTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Форматирует байты в читаемый формат (KB, MB, GB). Для нуля — «0 KB».
    func formatBytes(_ bytes: Int64) -> String {
        if bytes <= 0 {
            return "0 KB"
        }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        formatter.zeroPadsFractionDigits = false
        return formatter.string(fromByteCount: bytes)
    }

    /// URL-декодирует remark (в подписках часто содержит %-escaping эмодзи/кириллицы)
    /// и переводит русские названия серверов на английский.
    func decodedRemark(_ remark: String?) -> String {
        guard let remark = remark else { return "VPN Server" }
        let decoded = remark.removingPercentEncoding ?? remark
        return Self.translateServerName(decoded)
    }

    /// Переводит русские названия из подписок на английский (флаги-эмодзи сохраняем).
    /// Если перевода нет — возвращает оригинал.
    private static func translateServerName(_ name: String) -> String {
        var result = name
        let translations: [String: String] = [
            "Авто (лучший выбор)": "Auto (best choice)",
            "Авто": "Auto",
            "Германия (надёжный)": "Germany (reliable)",
            "Германия": "Germany",
            "Нидерланды": "Netherlands",
            "Франция": "France",
            "США": "USA",
            "Великобритания": "United Kingdom",
            "Швеция": "Sweden",
            "Польша": "Poland",
            "Чехия": "Czech Republic",
            "Финляндия": "Finland",
            "Латвия": "Latvia",
            "Эстония": "Estonia",
            "Литва": "Lithuania",
            "Япония": "Japan",
            "Сингапур": "Singapore",
            "Гонконг": "Hong Kong",
            "Турция": "Turkey",
            "ОАЭ": "UAE",
            "Канада": "Canada",
            "Только YouTube. Без рекламы": "YouTube only. Ad-free",
            "лучший выбор": "best choice",
            "надёжный": "reliable",
            "надежный": "reliable",
            "резвервный": "reserve",
            "резервный": "reserve",
            "быстрый": "fast",
            "только": "only",
            "без рекламы": "ad-free"
        ]
        for (ru, en) in translations {
            result = result.replacingOccurrences(of: ru, with: en)
        }
        return result
    }

    deinit {
        stopConnectionTimer()
        cancellables.removeAll()
    }
}
