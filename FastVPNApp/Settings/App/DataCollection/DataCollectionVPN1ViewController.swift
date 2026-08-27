import UIKit
import SwiftUI

class DataCollectionVPN1ViewController: UIViewController {

    /// true — первый вводный показ (до онбординга), false — открыт из настроек.
    private let isInitialPresentation: Bool

    init(isInitialPresentation: Bool = false) {
        self.isInitialPresentation = isInitialPresentation
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let vc = UIHostingController(
            rootView: DataCollectionVPN1View(
                isInitialPresentation: isInitialPresentation,
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

    /// "Agree & Continue" (только вводный показ) — отметить принятым и продолжить flow.
    private func handleAgree() {
        RemoteConfigService.shared.markDataCollectionAccepted()
        continueFlow()
    }

    /// Крестик (настройки) — просто закрыть.
    private func handleDismiss() {
        if isRoot() {
            continueFlow()
        } else {
            dismiss(animated: true)
        }
    }

    /// true, если этот VC — корневой (первый показ), а не открыт модально из настроек.
    private func isRoot() -> Bool {
        view.window?.rootViewController === self
    }

    /// Продолжить вводный flow: Data Collection уже показан ДО онбординга,
    /// поэтому дальше — Onboarding (если нужен) или сразу TabBar.
    private func continueFlow() {
        guard let window = view.window else { return }

        let nextVC: UIViewController
        if RemoteConfigService.shared.shouldShowOnboarding() {
            nextVC = OnboardingVPN1ViewController()
        } else {
            let tabBarVPN1VC = TabBarVPN1ViewController()
            tabBarVPN1VC.initialSelectedIndex = RemoteConfigService.shared.initialTabBarScreenIndex()
            nextVC = tabBarVPN1VC
        }

        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            window.rootViewController = nextVC
        }
    }
}
