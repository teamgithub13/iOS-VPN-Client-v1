import Foundation
import Combine
import FirebaseRemoteConfig

/// Сервис удалённых настроек Firebase Remote Config.
///
/// Загружает и активирует значения из Firebase, но не блокирует запуск приложения
/// при недоступности сети: в этом случае используются активированные или default-значения.
final class RemoteConfigService: ObservableObject {

    static let shared = RemoteConfigService()

    static let termsOfUseURLKey = "app_terms_of_use_url"
    static let appUsageDataURLKey = "app_usage_data"
    static let privacyPolicyURLKey = "privacy_policy_url"
    static let isShowOnboardingKey = "isShowOnboarding"
    static let initialTabBarScreenIndexKey = "init_tabBar_loan_screen_index"
    static let keitaroURLAfterAppLaunchKey = "app_keitaro_url_afterapplaunch"
    static let showLoaderByTimerKey = "app_show_loader_by_timer"
    static let getKeyBtnURLKey = "app_get_key_btn_url"

    private let onboardingCompletedKey = "com.fastvpn.onboarding.completed"
    private let dataCollectionAcceptedKey = "com.fastvpn.dataCollection.accepted"

    @Published private(set) var isActivated = false

    private let remoteConfig: RemoteConfig

    private init() {
        remoteConfig = RemoteConfig.remoteConfig()

        let settings = RemoteConfigSettings()
        // Всегда тянем свежие значения при холодном старте — без часового кеша,
        // чтобы актуальный URL Keitaro определялся при каждом запуске.
        settings.minimumFetchInterval = 0
        settings.fetchTimeout = 10
        remoteConfig.configSettings = settings
    }

    /// Загружает актуальные значения и активирует их в текущей сессии.
    func fetchAndActivate(completion: ((Bool, Error?) -> Void)? = nil) {
        remoteConfig.fetchAndActivate { status, error in
            let succeeded = error == nil && status != .error
            DispatchQueue.main.async {
                self.isActivated = succeeded
                completion?(succeeded, error)
            }
        }
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

    func initialTabBarScreenIndex() -> Int {
        let index = max(0, int(forKey: Self.initialTabBarScreenIndexKey, defaultValue: 0))
#if DEBUG
        print("Remote Config \(Self.initialTabBarScreenIndexKey): \(index)")
#endif
        return index
    }

    func keitaroURLAfterAppLaunch() -> URL? {
        guard let value = string(forKey: Self.keitaroURLAfterAppLaunchKey),
              let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }

        return url
    }

    /// Показывает ли приложение onboarding в текущем состоянии.
    /// Remote Config должен разрешить показ, и пользователь ещё не должен
    /// завершить onboarding на этом устройстве.
    func shouldShowOnboarding() -> Bool {
        bool(forKey: Self.isShowOnboardingKey, defaultValue: false)
            && !UserDefaults.standard.bool(forKey: onboardingCompletedKey)
    }

    func markOnboardingCompleted() {
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
    }

    // MARK: - Data Collection (показ 1 раз после онбординга/запуска)

    /// true, если экран Data Collection ещё не был принят на этом устройстве.
    func shouldShowDataCollection() -> Bool {
        !UserDefaults.standard.bool(forKey: dataCollectionAcceptedKey)
    }

    /// Отметить, что пользователь принял Data Collection (больше не показывать автоматически).
    func markDataCollectionAccepted() {
        UserDefaults.standard.set(true, forKey: dataCollectionAcceptedKey)
    }
}
