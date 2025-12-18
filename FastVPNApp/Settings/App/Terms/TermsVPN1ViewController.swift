import UIKit
import SwiftUI

class TermsVPN1ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let vc = UIHostingController(rootView: TermsVPN1View(dismissVPN1Action: {
            self.dismiss(animated: true)
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
