import SwiftUI

struct PrivacyPolicyVPN1View: View {
    
    var dismissVPN1Action: (() -> Void)?

    @State private var privacyPolicyURL: URL?

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
            } else {
                ProgressView()
                    .frame(maxHeight: .infinity)
            }
        }
        .padding()
        .task {
            guard privacyPolicyURL == nil else { return }
            privacyPolicyURL = await RemoteConfigService.shared.loadURL(
                forKey: RemoteConfigService.privacyPolicyURLKey,
                fallback: "https://www.dzen.ru/"
            )
        }
    }
}

#Preview {
    PrivacyPolicyVPN1View()
}
