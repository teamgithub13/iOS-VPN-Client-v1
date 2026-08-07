import UIKit
import SwiftUI

class AppVPN1ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vc = UIHostingController(rootView: AppVPN1View(dismissVPN1Action: {
            self.dismiss(animated: true)
        }, privacyVPN1Action: {
            let privacyVPN1VC = PrivacyPolicyVPN1ViewController()
            privacyVPN1VC.modalPresentationStyle = .fullScreen
            self.present(privacyVPN1VC, animated: true)
        },
           dataCollectionVPN1Action: {
            let dataCollectionVPN1VC = DataCollectionVPN1ViewController()
            dataCollectionVPN1VC.modalPresentationStyle = .fullScreen
            self.present(dataCollectionVPN1VC, animated: true)
        },
            termsVPN1Action: {
            let termsVPN1VC = TermsVPN1ViewController()
            termsVPN1VC.modalPresentationStyle = .fullScreen
            self.present(termsVPN1VC, animated: true)
        }, supportVPN1Action: {
            let supportVPN1VC = SupportVPN1ViewController()
            supportVPN1VC.modalPresentationStyle = .fullScreen
            self.present(supportVPN1VC, animated: true)
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
