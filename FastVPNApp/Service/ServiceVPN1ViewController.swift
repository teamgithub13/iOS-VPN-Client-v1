import UIKit
import SwiftUI

class ServiceVPN1ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let viewModel = ServiceVPN1ViewModel()
        viewModel.openSupport = { [weak self] in
            let supporvpn1 = SupportVPN1ViewController()
            supporvpn1.modalPresentationStyle = .fullScreen
            self?.present(supporvpn1, animated: true)
        }

        let vc = UIHostingController(rootView: ServiceVPN1View(
            viewModel: viewModel
        ))

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
