import SwiftUI

struct OnDemandVPN1View: View {
    
    var dismissVPN1Action: (() -> Void)?
    
    @State private var onDemandVPN1 = false
    
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
                
                Text("On Demand")
                    .font(.custom("AlbertSans-SemiBold", size: 28))
            }
            
            HStack(spacing: 20) {
                Text("Use on demand")
                    .font(.custom("AlbertSans-SemiBold", size: 20))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(onDemandVPN1 ? "switchOnVPN1" : "switchOffVPN1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 32)
                    .onTapGesture {
                        onDemandVPN1.toggle()
                        UserDefaults.standard.set(onDemandVPN1, forKey: "OnDemandVPN1VPN1")
                    }
            }
            .padding()
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.05), radius: 30)
            )
            
            Spacer()
        }
        .padding()
        .onAppear {
            onDemandVPN1 = UserDefaults.standard.bool(forKey: "OnDemandVPN1VPN1")
        }
    }
}

#Preview {
    OnDemandVPN1View()
}
