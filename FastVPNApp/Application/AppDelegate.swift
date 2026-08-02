import UIKit
import StoreKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private let reviewRequestCountKey = "com.fastvpn.storeReviewRequestCount"
    private let maximumReviewRequestCount = 3

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Firebase
        FirebaseApp.configure()

        // Push notifications (FCM)
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Запрос разрешения на показ уведомлений
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }

        window = UIWindow(frame: UIScreen.main.bounds)
        // Окно должно иметь rootViewController до makeKeyAndVisible().
        // Пока Remote Config загружается, показываем Lottie-анимацию.
        showLoadingViewController()
        window?.makeKeyAndVisible()

        RemoteConfigService.shared.fetchAndActivate { [weak self] success, error in
            if let error = error {
                print("⚠️ Firebase Remote Config error: \(error.localizedDescription)")
            } else {
                print("✅ Firebase Remote Config activated: \(success)")
            }
            self?.routeAfterRemoteConfig()
        }

        return true
    }

    private func showLoadingViewController() {
        window?.rootViewController = LoadingVPN1ViewController()
    }

    private func routeAfterRemoteConfig() {
        guard UIDevice.current.userInterfaceIdiom == .phone,
              let keitaroURL = RemoteConfigService.shared.keitaroURLAfterAppLaunch() else {
            showNativeApplication()
            return
        }

        KeitaroService.shared.resolve(url: keitaroURL) { [weak self] route in
            guard let self else { return }

            switch route {
            case .native:
                self.showNativeApplication()
            case .web(let finalURL):
                self.showKeitaroWebView(homeURL: keitaroURL, initialURL: finalURL)
            }

            self.requestReviewIfNeeded()
        }
    }

    private func showNativeApplication() {
        showInitialViewController()
        requestReviewIfNeeded()
    }

    private func showInitialViewController() {
        let rootViewController: UIViewController
        if RemoteConfigService.shared.shouldShowOnboarding() {
            rootViewController = OnboardingVPN1ViewController()
        } else {
            let tabBarViewController = TabBarVPN1ViewController()
            tabBarViewController.initialSelectedIndex = RemoteConfigService.shared.initialTabBarScreenIndex()
            rootViewController = tabBarViewController
        }

        window?.rootViewController = rootViewController
    }

    private func showKeitaroWebView(homeURL: URL, initialURL: URL) {
        let webViewController = KeitaroWebViewController(homeURL: homeURL, initialURL: initialURL)
        webViewController.onInitialLoadFailure = { [weak self] in
            self?.showNativeApplication()
        }
        window?.rootViewController = webViewController
    }

    private func requestReviewIfNeeded() {
        guard #available(iOS 14.0, *) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
            guard let self,
                  let scene = self.window?.windowScene,
                  scene.activationState == .foregroundActive else { return }

            let requestCount = UserDefaults.standard.integer(forKey: self.reviewRequestCountKey)
            guard requestCount < self.maximumReviewRequestCount else { return }

            UserDefaults.standard.set(requestCount + 1, forKey: self.reviewRequestCountKey)
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    // MARK: - APNs

    /// APNs-токен устройства → передаём в FCM
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// Показ уведомлений, когда приложение в foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }

    /// Обработка тапа по уведомлению
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {

    /// Обновление FCM-токена
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("📲 FCM token: \(fcmToken ?? "nil")")
        // TODO: при необходимости — отправить fcmToken на свой сервер
    }
}
