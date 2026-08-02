import SwiftUI

struct PrivacyPolicyVPN1View: View {
    
    var dismissVPN1Action: (() -> Void)?

    @ObservedObject private var remoteConfig = RemoteConfigService.shared

    private var privacyPolicyURL: URL? {
        let fallback = "https://www.dzen.ru/"
        return URL(string: remoteConfig.string(
            forKey: RemoteConfigService.privacyPolicyURLKey,
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
                
                Text("Privacy Policy")
                    .font(.custom("AlbertSans-SemiBold", size: 28))
            }
            
            if let urlVPN1 = privacyPolicyURL {
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

#Preview {
    PrivacyPolicyVPN1View()
}
