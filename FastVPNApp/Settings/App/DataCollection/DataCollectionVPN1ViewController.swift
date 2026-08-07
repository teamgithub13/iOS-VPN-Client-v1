import UIKit
import SwiftUI

class DataCollectionVPN1ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let vc = UIHostingController(
            rootView: DataCollectionVPN1View(
                dismissVPN1Action: { [weak self] in
                    self?.handleDismiss()
                },
                agreeAction: { [weak self] in
                    self?.handleAgree()
                },
                privacyPolicyVPN1Action: { [weak self] in
                    guard let self else { return }
                    let privacyVPN1VC = PrivacyPolicyVPN1ViewController()
                    privacyVPN1VC.modalPresentationStyle = .fullScreen
                    self.present(privacyVPN1VC, animated: true)
                })
        )

        let swiftuiView = vc.view

        guard let swiftuiView else { return }

        swiftuiView.translatesAutoresizingMaskIntoConstraints = false

        self.addChild(vc)
        self.view.addSubview(swiftuiView)

        NSLayoutConstraint.activate([
            swiftuiView.topAnchor.constraint(equalTo: self.view.topAnchor),
            swiftuiView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            swiftuiView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            swiftuiView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])

        vc.didMove(toParent: self)
    }

    // MARK: - Actions

    /// "Agree & Continue" — отметить принятым и открыть приложение (TabBar) или закрыть.
    private func handleAgree() {
        RemoteConfigService.shared.markDataCollectionAccepted()
        if isRoot() {
            showTabBar()
        } else {
            dismiss(animated: true)
        }
    }

    /// Крестик — закрыть (modal) или открыть TabBar без отметки (root).
    private func handleDismiss() {
        if isRoot() {
            showTabBar()
        } else {
            dismiss(animated: true)
        }
    }

    /// true, если этот VC — корневой (первый показ после запуска/онбординга),
    /// а не открыт модально из настроек.
    private func isRoot() -> Bool {
        view.window?.rootViewController === self
    }

    /// Переход в TabBar (cross-dissolve), как в OnboardingVPN1ViewController.
    private func showTabBar() {
        guard let window = view.window else { return }
        let tabBarVPN1VC = TabBarVPN1ViewController()
        tabBarVPN1VC.initialSelectedIndex = RemoteConfigService.shared.initialTabBarScreenIndex()
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            window.rootViewController = tabBarVPN1VC
        }
    }
}
