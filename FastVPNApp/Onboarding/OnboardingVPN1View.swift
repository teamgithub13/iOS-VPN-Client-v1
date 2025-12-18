import SwiftUI

struct OnboardingVPN1View: View {
    
    var tabBarVPN1Action: (() -> Void)?
    
    private let onbImagesVPN1 = [
        "onb1VPN1",
        "onb2VPN1",
        "onb3VPN1",
        "onb4VPN1"
    ]
    
    private let textsVPN1 = [
        "High-quality and fast connection in our app",
        "Our support is always available for connection questions.",
        "You can measure your connection speed directly in the app.",
        "Lots of settings for your connection"
    ]
    
    @State private var indexVPN1 = 0
    
    var body: some View {
        VStack {
            Image(onbImagesVPN1[indexVPN1])
                .resizable()
                .edgesIgnoringSafeArea(.top)
            
            VStack(spacing: 20) {
                Text(textsVPN1[indexVPN1])
                    .font(.custom("AlbertSans-SemiBold", size: 28))
                    .multilineTextAlignment(.center)
                
                HStack {
                    if indexVPN1 > 0 {
                        Button {
                            if indexVPN1 > 0 {
                                indexVPN1 -= 1
                            }
                        } label: {
                            Image("onbBackVPN1")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 32)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        if indexVPN1 == onbImagesVPN1.count - 1 {
                            tabBarVPN1Action?()
                        } else {
                            indexVPN1 += 1
                        }
                    } label: {
                        Image("onbForwardVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 32)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    OnboardingVPN1View()
}
