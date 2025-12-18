import UIKit
import SwiftUI

class TunnelSettingsVPN1ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vc = UIHostingController(rootView: TunnelSettingsVPN1View(dismissVPN1Action: {
            self.dismiss(animated: true)
        }, presetsVPN1Action: {
            let presetsVPN1VC = PresetsVPN1ViewController()
            presetsVPN1VC.modalPresentationStyle = .fullScreen
            self.present(presetsVPN1VC, animated: true)
        }, routingVPN1Action: {
            let routingVPN1VC = RoutingVPN1ViewController()
            routingVPN1VC.modalPresentationStyle = .fullScreen
            self.present(routingVPN1VC, animated: true)
        }, onDemandVPN1Action: {
            let onDemandVPN1VC = OnDemandVPN1ViewController()
            onDemandVPN1VC.modalPresentationStyle = .fullScreen
            self.present(onDemandVPN1VC, animated: true)
        }, pingVPN1Action: {
            let pingVPN1VC = PingVPN1ViewController()
            pingVPN1VC.modalPresentationStyle = .fullScreen
            self.present(pingVPN1VC, animated: true)
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
