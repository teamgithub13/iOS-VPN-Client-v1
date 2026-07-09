import Foundation

/// Хранилище списка серверов и URL подписки в стандартном `UserDefaults`.
///
/// App Group используется только для передачи выбранной конфигурации в PacketTunnel
/// (см. `VPNConnectionService`); здесь мы храним лишь UI-состояние приложения.
final class ServerRepository {

    static let shared = ServerRepository()

    private let defaults = UserDefaults.standard
    private let serversKey = "com.fastvpn.servers"
    private let subscriptionURLKey = "com.fastvpn.subscriptionURL"
    private let selectedIndexKey = "com.fastvpn.selectedIndex"

    private init() {}

    // MARK: - Servers

    func loadServers() -> [VPNConfiguration] {
        guard let data = defaults.data(forKey: serversKey) else { return [] }
        return (try? JSONDecoder().decode([VPNConfiguration].self, from: data)) ?? []
    }

    func saveServers(_ servers: [VPNConfiguration]) {
        if let data = try? JSONEncoder().encode(servers) {
            defaults.set(data, forKey: serversKey)
        }
    }

    func clearServers() {
        defaults.removeObject(forKey: serversKey)
    }

    // MARK: - Subscription URL

    func loadSubscriptionURL() -> String? {
        defaults.string(forKey: subscriptionURLKey)
    }

    func saveSubscriptionURL(_ url: String?) {
        if let url = url {
            defaults.set(url, forKey: subscriptionURLKey)
        } else {
            defaults.removeObject(forKey: subscriptionURLKey)
        }
    }

    // MARK: - Selected index

    func loadSelectedIndex() -> Int? {
        let value = defaults.integer(forKey: selectedIndexKey)
        return defaults.object(forKey: selectedIndexKey) == nil ? nil : value
    }

    func saveSelectedIndex(_ index: Int?) {
        if let index = index {
            defaults.set(index, forKey: selectedIndexKey)
        } else {
            defaults.removeObject(forKey: selectedIndexKey)
        }
    }
}
