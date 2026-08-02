import SwiftUI
import WebKit

struct SupportVPN1View: View {

    var dismissVPN1Action: (() -> Void)?

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

                Text("Support")
                    .font(.custom("AlbertSans-SemiBold", size: 28))
            }

            if let urlVPN1 = URL(string: "https://jivo.chat/cmCpCjI83u") {
                WebViewVPN1(urlVPN1: urlVPN1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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

extension UIApplication {
    func hideKeyboardVPN1() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    SupportVPN1View()
}
