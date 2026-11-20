import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Firebase
        FirebaseApp.configure()

        // Прогреваем сетевой монитор — первый path update асинхронный,
        // без этого первое нажатие VPN может получить ложный offline.
        _ = InternetAvailabilityService.shared

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
        showInitialViewController()
        window?.makeKeyAndVisible()
        return true
    }

    private func showInitialViewController() {
        let rootViewController: UIViewController
        if DataCollectionVPN1ViewController.shouldShowOnLaunch {
            // Согласие на сбор данных — ДО онбординга (политика Apple)
            rootViewController = DataCollectionVPN1ViewController(isInitialPresentation: true)
        } else {
            rootViewController = OnboardingVPN1ViewController.makeInitialViewController()
        }

        window?.rootViewController = rootViewController
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
