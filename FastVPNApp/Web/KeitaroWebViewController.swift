import UIKit
import WebKit
import Lottie
import Network

final class KeitaroWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    private let homeURL: URL
    private let initialURL: URL
    private let webView: WKWebView
    private let toolbar = UIToolbar()
    private let loadingOverlay = UIView()
    private let loadingAnimationView = LottieAnimationView(name: "GeometricLoaderVpn1")
    private let pathMonitor = NWPathMonitor()
    private let pathMonitorQueue = DispatchQueue(label: "com.fastvpn.webview-internet-monitor")
    private var loaderHideWorkItem: DispatchWorkItem?
    private var didFinishInitialLoad = false

    var onInitialLoadFailure: (() -> Void)?

    init(homeURL: URL, initialURL: URL) {
        self.homeURL = homeURL
        self.initialURL = initialURL

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        webView = WKWebView(frame: .zero, configuration: configuration)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupWebView()
        setupToolbar()
        setupLoadingOverlay()

        load(url: initialURL)
        startInternetMonitoring()
    }

    deinit {
        pathMonitor.cancel()
    }

    private func setupWebView() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupToolbar() {
        let homeButton = UIBarButtonItem(
            image: UIImage(systemName: "house"),
            style: .plain,
            target: self,
            action: #selector(openHome)
        )
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
        let forwardButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.forward"),
            style: .plain,
            target: self,
            action: #selector(goForward)
        )

        toolbar.translatesAutoresizingMaskIntoConstraints = false
        // Расположение: [назад] --- flex --- [домой] --- flex --- [вперёд]
        toolbar.items = [
            backButton,
            .flexibleSpace(),
            homeButton,
            .flexibleSpace(),
            forwardButton
        ]
        view.addSubview(toolbar)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: webView.bottomAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupLoadingOverlay() {
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.backgroundColor = .clear
        loadingOverlay.isUserInteractionEnabled = true

        loadingAnimationView.translatesAutoresizingMaskIntoConstraints = false
        loadingAnimationView.contentMode = .scaleAspectFit
        loadingAnimationView.loopMode = .loop
        loadingAnimationView.animationSpeed = 1

        view.addSubview(loadingOverlay)
        loadingOverlay.addSubview(loadingAnimationView)

        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: webView.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            loadingAnimationView.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            loadingAnimationView.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor),
            loadingAnimationView.widthAnchor.constraint(equalToConstant: 180),
            loadingAnimationView.heightAnchor.constraint(equalToConstant: 180)
        ])

        loadingAnimationView.play()
        startLoaderTimerIfNeeded()
    }

    @objc private func openHome() {
        load(url: homeURL)
    }

    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    @objc private func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didFinishInitialLoad = true
        hideLoadingOverlay()
        updateNavigationButtons()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        hideLoadingOverlay()
        _ = handleOfflineError(error)
        updateNavigationButtons()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        hideLoadingOverlay()
        if handleOfflineError(error) {
            return
        }
        guard !didFinishInitialLoad else { return }
        onInitialLoadFailure?()
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        showLoadingOverlay()
        startLoaderTimerIfNeeded()
    }

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            load(request: navigationAction.request)
        }

        return nil
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    private func load(url: URL) {
        load(request: URLRequest(url: url))
    }

    private func load(request: URLRequest) {
        webView.load(request)
    }

    private func startInternetMonitoring() {
        pathMonitor.pathUpdateHandler = { path in
            guard path.status == .unsatisfied else { return }
            InternetAvailabilityService.shared.showOfflineAlert()
        }
        pathMonitor.start(queue: pathMonitorQueue)
    }

    private func handleOfflineError(_ error: Error) -> Bool {
        guard let urlError = error as? URLError,
              urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost else {
            return false
        }

        InternetAvailabilityService.shared.showOfflineAlert()
        return true
    }

    private func updateNavigationButtons() {
        // Порядок: [0]=back, [1]=flex, [2]=home, [3]=flex, [4]=forward
        guard let items = toolbar.items, items.count == 5 else { return }
        items[0].isEnabled = webView.canGoBack
        items[4].isEnabled = webView.canGoForward
    }

    private func startLoaderTimerIfNeeded() {
        loaderHideWorkItem?.cancel()

        guard RemoteConfigService.shared.bool(
            forKey: RemoteConfigService.showLoaderByTimerKey,
            defaultValue: false
        ) else { return }

        let workItem = DispatchWorkItem { [weak self] in
            self?.hideLoadingOverlay()
        }
        loaderHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: workItem)
    }

    private func showLoadingOverlay() {
        loadingOverlay.isHidden = false
        loadingAnimationView.play()
    }

    private func hideLoadingOverlay() {
        loaderHideWorkItem?.cancel()
        loaderHideWorkItem = nil
        loadingAnimationView.stop()
        loadingOverlay.isHidden = true
    }
}
