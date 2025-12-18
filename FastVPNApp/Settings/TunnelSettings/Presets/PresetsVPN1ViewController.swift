import UIKit
import SwiftUI

class PresetsVPN1ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vc = UIHostingController(rootView: PresetsVPN1View(dismissVPN1Action: {
            self.dismiss(animated: true)
        }, createRulesVPN1Action: {
            let myRulesVPN1VC = MyRulesVPN1ViewController()
            myRulesVPN1VC.modalPresentationStyle = .fullScreen
            self.present(myRulesVPN1VC, animated: true)
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
