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
    
    private let vpnService = VPNConnectionService.shared
    private var cancellables = Set<AnyCancellable>()
    private var connectionTimer: Timer?
    private var startTime: Date?
    
    init() {
        setupObservers()
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
            errorMessage = nil
        case .disconnecting:
            isConnected = false
            errorMessage = nil
        case .error(let message):
            isConnected = false
            stopConnectionTimer()
            connectionTime = 0
            errorMessage = message
        }
    }
    
    private func startConnectionTimer() {
        stopConnectionTimer()
        connectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.connectionTime = Date().timeIntervalSince(startTime)
        }
    }
    
    private func stopConnectionTimer() {
        connectionTimer?.invalidate()
        connectionTimer = nil
        startTime = nil
    }
    
    /// Переключает состояние VPN подключения
    func toggleVPN() {
        // Если конфигурация не установлена, используем пример из запроса
        if vpnService.currentConfiguration == nil {
            let exampleURL = "vless://33e24a0e-71e5-4fed-9e24-29d8364a65cd@83.143.113.229:443?security=reality&sni=www.bing.com&alpn=h2&fp=chrome&pbk=ckRcueERkPqqjZABwxqni_J_Nbb70Q6k5fEEUAjoImw&type=tcp&flow=xtls-rprx-vision&encryption=none#avovpn.com-5476184-4036300"
            _ = vpnService.setConfiguration(from: exampleURL)
        }
        
        vpnService.toggleConnection()
    }
    
    /// Устанавливает конфигурацию из VLESS URL
    func setConfiguration(from url: String) -> Bool {
        return vpnService.setConfiguration(from: url)
    }
    
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
    
    deinit {
        stopConnectionTimer()
        cancellables.removeAll()
    }
}

