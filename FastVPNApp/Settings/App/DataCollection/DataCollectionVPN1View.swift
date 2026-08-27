import SwiftUI
import WebKit

struct DataCollectionVPN1View: View {

    /// true — первый вводный показ (до онбординга): кнопки Agree & Continue + Privacy Policy.
    /// false — открыт из настроек: крестик назад + заголовок + контент, как у Privacy/Terms.
    var isInitialPresentation: Bool = false

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
            // Хедер: крестик (только в настройках) + заголовок — по паттерну Privacy/Terms
            ZStack {
                if !isInitialPresentation {
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
                }

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

            // Кнопки — только на первом вводном экране
            if isInitialPresentation {
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
        }
        .padding()
    }
}
