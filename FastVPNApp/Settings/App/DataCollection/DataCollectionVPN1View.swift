import SwiftUI
import WebKit

struct DataCollectionVPN1View: View {

    var dismissVPN1Action: (() -> Void)?
    var agreeAction: (() -> Void)?
    var privacyPolicyVPN1Action: (() -> Void)?

    @ObservedObject private var remoteConfig = RemoteConfigService.shared

    private var appUsageDataURL: URL? {
        let fallback = "https://www.google.com/"
        return URL(string: remoteConfig.string(
            forKey: RemoteConfigService.appUsageDataURLKey,
            defaultValue: fallback
        ) ?? fallback)
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Text("Data Collection & usage")
                    .font(.custom("AlbertSans-SemiBold", size: 28))
            }

            if let urlVPN1 = appUsageDataURL {
                WebViewVPN1(urlVPN1: urlVPN1)
                    .frame(maxHeight: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.gray.opacity(0.5), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            Button {
                agreeAction?()
            } label: {
                Text("Agree & Continue")
                    .font(.custom("AlbertSans-SemiBold", size: 16))
                    .foregroundStyle(.black)
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(red: 0.879, green: 0.961, blue: 0.496))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.black, lineWidth: 1)
                    )
            }

            Button {
                privacyPolicyVPN1Action?()
            } label: {
                Text("Privacy Policy")
                    .font(.custom("AlbertSans-SemiBold", size: 16))
                    .foregroundStyle(.black)
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(red: 0.879, green: 0.961, blue: 0.496))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.black, lineWidth: 1)
                    )
            }
        }
        .padding()
    }
}
