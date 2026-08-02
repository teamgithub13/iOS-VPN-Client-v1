import UIKit
import Lottie

final class LoadingVPN1ViewController: UIViewController {

    private let animationView = LottieAnimationView(name: "GeometricLoaderVpn1")

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.animationSpeed = 1

        view.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            animationView.widthAnchor.constraint(equalToConstant: 180),
            animationView.heightAnchor.constraint(equalToConstant: 180)
        ])

        animationView.play()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        animationView.stop()
    }
}
