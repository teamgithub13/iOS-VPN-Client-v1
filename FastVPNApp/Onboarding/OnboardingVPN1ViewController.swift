import UIKit
import SwiftUI

class OnboardingVPN1ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vc = UIHostingController(rootView: OnboardingVPN1View(tabBarVPN1Action: {
            RemoteConfigService.shared.markOnboardingCompleted()

            guard let window = self.view.window else { return }
            let tabBarVPN1VC = TabBarVPN1ViewController()
            tabBarVPN1VC.initialSelectedIndex = RemoteConfigService.shared.initialTabBarScreenIndex()
            UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
                window.rootViewController = tabBarVPN1VC
            }
        }))
        
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


}
