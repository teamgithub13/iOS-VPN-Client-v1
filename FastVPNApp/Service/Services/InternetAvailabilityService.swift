import Foundation
import Network
import UIKit

final class InternetAvailabilityService {

    static let shared = InternetAvailabilityService()

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.fastvpn.internet-monitor")

    private init() {
        monitor.start(queue: monitorQueue)
    }

    var isConnected: Bool {
        // The monitor may report .requiresConnection before its first path update.
        // Let the request proceed in that transitional state so WebView can report
        // the actual network error instead of showing a false offline alert.
        monitor.currentPath.status != .unsatisfied
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
