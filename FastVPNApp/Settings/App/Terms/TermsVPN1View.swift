import SwiftUI
import WebKit

struct TermsVPN1View: View {
    
    var dismissVPN1Action: (() -> Void)?

    @ObservedObject private var remoteConfig = RemoteConfigService.shared

    private var termsOfUseURL: URL? {
        let fallback = "https://www.google.com/"
        return URL(string: remoteConfig.string(
            forKey: RemoteConfigService.termsOfUseURLKey,
            defaultValue: fallback
        ) ?? fallback)
    }
    
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
            }
        }
        .padding()
        .onAppear {
            if !InternetAvailabilityService.shared.isConnected {
                InternetAvailabilityService.shared.showOfflineAlert()
            }
        }
    }
}

struct WebViewVPN1: UIViewRepresentable {
    let urlVPN1: URL
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let requestVPN1 = URLRequest(url: urlVPN1)
        uiView.load(requestVPN1)
    }
}

#Preview {
    TermsVPN1View()
}
