import UIKit
import SwiftUI

class SettingsVPN1ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vc = UIHostingController(rootView: SettingsVPN1View(appSettingsVPN1Action: {
            let appVPN1VC = AppVPN1ViewController()
            appVPN1VC.modalPresentationStyle = .fullScreen
            self.present(appVPN1VC, animated: true)
        }, tunnelSettingsVPN1Action: {
            let tunnelSettingsVPN1VC = TunnelSettingsVPN1ViewController()
            tunnelSettingsVPN1VC.modalPresentationStyle = .fullScreen
            self.present(tunnelSettingsVPN1VC, animated: true)
        }, statisticsVPN1Action: {
            let statisticsVPN1VC = StatisticsVPN1ViewController()
            statisticsVPN1VC.modalPresentationStyle = .fullScreen
            self.present(statisticsVPN1VC, animated: true)
        }))
        
        let swiftuiView = vc.view
        
        guard let swiftuiView else { return }
        
        swiftuiView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addChild(vc)
        self.view.addSubview(swiftuiView)
        
        NSLayoutConstraint.activate([
            swiftuiView.topAnchor.constraint(equalTo: self.view.topAnchor),
            swiftuiView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            swiftuiView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            swiftuiView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        
        vc.didMove(toParent: self)
    }
}
