import SwiftUI
import WebKit

struct TermsVPN1View: View {
    
    var dismissVPN1Action: (() -> Void)?

    @State private var termsOfUseURL: URL?

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                HStack {
                    Button {
                        dismissVPN1Action?()
                    } label: {
                        Image("dismissVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                    
                    Spacer()
                }
                
                Text("Terms")
                    .font(.custom("AlbertSans-SemiBold", size: 28))
            }
            
            if let urlVPN1 = termsOfUseURL {
                WebViewVPN1(urlVPN1: urlVPN1)
                    .frame(maxHeight: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.gray.opacity(0.5), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                ProgressView()
                    .frame(maxHeight: .infinity)
            }
        }
        .padding()
        .task {
            guard termsOfUseURL == nil else { return }
            termsOfUseURL = await RemoteConfigService.shared.loadURL(
                forKey: RemoteConfigService.termsOfUseURLKey,
                fallback: "https://www.google.com/"
            )
        }
    }
}

struct WebViewVPN1: UIViewRepresentable {
    let urlVPN1: URL

    func makeCoordinator() -> NavigationDelegateVPN1 {
        NavigationDelegateVPN1()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let requestVPN1 = URLRequest(url: urlVPN1)
        uiView.load(requestVPN1)
    }
}

/// Делегат навигации WKWebView для показа алерта при реальной ошибке сети.
/// Заменяет превентивную проверку isConnected при появлении экрана,
/// которая часто ложно срабатывала в переходном состоянии NWPathMonitor.
final class NavigationDelegateVPN1: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        guard let urlError = error as? URLError,
              urlError.code == .notConnectedToInternet
                || urlError.code == .networkConnectionLost else { return }
        InternetAvailabilityService.shared.showOfflineAlert()
    }
}

#Preview {
    TermsVPN1View()
}
