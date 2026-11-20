import Foundation
import FirebaseRemoteConfig

final class RemoteConfigService {

    static let shared = RemoteConfigService()

    static let termsOfUseURLKey = "app_terms_of_use_url"
    static let appUsageDataURLKey = "app_usage_data"
    static let privacyPolicyURLKey = "privacy_policy_url"

    private let remoteConfig: RemoteConfig

    private init() {
        remoteConfig = RemoteConfig.remoteConfig()

        let settings = RemoteConfigSettings()
        settings.fetchTimeout = 10
        remoteConfig.configSettings = settings
    }

    /// Загружается при открытии раздела, которому нужна удалённая ссылка.
    @MainActor
    func loadURL(forKey key: String, fallback: String) async -> URL? {
        _ = try? await remoteConfig.fetchAndActivate()
        if let value = string(forKey: key), let url = URL(string: value) {
            return url
        }
        return URL(string: fallback)
    }

    /// Устанавливает локальные значения, используемые до первой успешной загрузки.
    func setDefaults(_ defaults: [String: NSObject]) {
        remoteConfig.setDefaults(defaults)
    }

    func string(forKey key: String, defaultValue: String? = nil) -> String? {
        let value = remoteConfig.configValue(forKey: key)
        return value.source == .static ? defaultValue : value.stringValue
    }

    func bool(forKey key: String, defaultValue: Bool = false) -> Bool {
        let value = remoteConfig.configValue(forKey: key)
        return value.source == .static ? defaultValue : value.boolValue
    }

    func int(forKey key: String, defaultValue: Int = 0) -> Int {
        let value = remoteConfig.configValue(forKey: key)
        guard value.source != .static else { return defaultValue }

        let stringValue = value.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(stringValue) ?? value.numberValue.intValue
    }

    func double(forKey key: String, defaultValue: Double = 0) -> Double {
        let value = remoteConfig.configValue(forKey: key)
        return value.source == .static ? defaultValue : value.numberValue.doubleValue
    }
}
