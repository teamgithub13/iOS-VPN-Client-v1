import UIKit

class TabBarVPN1ViewController: UITabBarController {

    var initialSelectedIndex = 0 {
        didSet {
            guard isViewLoaded else { return }
            applyInitialSelectedIndex()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let serviceVPN1VC = ServiceVPN1ViewController()
        serviceVPN1VC.tabBarItem = UITabBarItem(title: "Service", image: UIImage(named: "serviceVPN1Icon"), tag: 0)
        
        let speedVPN1VC = SpeedVPN1ViewController()
        speedVPN1VC.tabBarItem = UITabBarItem(title: "Speed", image: UIImage(named: "speedVPN1Icon"), tag: 1)
        
        let settingsVPN1VC = SettingsVPN1ViewController()
        settingsVPN1VC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(named: "settingsVPN1Icon"), tag: 2)
        
        viewControllers = [serviceVPN1VC, speedVPN1VC, settingsVPN1VC]
        applyInitialSelectedIndex()
        
        tabBar.tintColor = .black
    }

    private func applyInitialSelectedIndex() {
        guard let viewControllers, !viewControllers.isEmpty else { return }
        selectedIndex = min(max(initialSelectedIndex, 0), viewControllers.count - 1)
    }
}
