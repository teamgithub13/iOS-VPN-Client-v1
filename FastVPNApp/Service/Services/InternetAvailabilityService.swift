import Foundation
import Network
import UIKit

final class InternetAvailabilityService {

    static let shared = InternetAvailabilityService()

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.fastvpn.internet-monitor")

    /// Последний полученный статус сети. Доступ — только на monitorQueue.
    /// nil = первый path update ещё не пришёл (NWPathMonitor стартует асинхронно,
    /// а его currentPath до первого апдейта — .unsatisfied, что давало ложный
    /// «No Internet Connection» при первом нажатии VPN после запуска приложения).
    private var lastStatus: NWPath.Status?

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.lastStatus = path.status
        }
        monitor.start(queue: monitorQueue)
    }

    var isConnected: Bool {
        let status = monitorQueue.sync { lastStatus }
        // Пока статус неизвестен (nil) — не блокируем пользователя:
        // если сети реально нет, сам запрос покажет настоящую ошибку.
        return status != .unsatisfied
    }

    func showOfflineAlert() {
        DispatchQueue.main.async {
            guard let viewController = Self.topViewController(),
                  viewController.presentedViewController as? UIAlertController == nil else { return }

            let alert = UIAlertController(
                title: "No Internet Connection",
                message: "Check your internet connection",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            viewController.present(alert, animated: true)
        }
    }

    private static func topViewController(from viewController: UIViewController? = nil) -> UIViewController? {
        let rootViewController = viewController ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController

        if let navigationController = rootViewController as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }
        if let tabBarController = rootViewController as? UITabBarController {
            return topViewController(from: tabBarController.selectedViewController)
        }
        if let presentedViewController = rootViewController?.presentedViewController {
            return topViewController(from: presentedViewController)
        }

        return rootViewController
    }
}
