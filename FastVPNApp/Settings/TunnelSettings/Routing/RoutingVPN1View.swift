import SwiftUI

struct RoutingVPN1View: View {
    
    var dismissVPN1Action: (() -> Void)?
    
    @State private var useRoutingVPN1 = false
    
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
                
                Text("Routing")
                    .font(.custom("AlbertSans-SemiBold", size: 28))
            }
            
            HStack(spacing: 20) {
                Text("Use routing")
                    .font(.custom("AlbertSans-SemiBold", size: 20))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(useRoutingVPN1 ? "switchOnVPN1" : "switchOffVPN1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 32)
                    .onTapGesture {
                        useRoutingVPN1.toggle()
                        UserDefaults.standard.set(useRoutingVPN1, forKey: "UseRoutingVPN1")
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
            useRoutingVPN1 = UserDefaults.standard.bool(forKey: "UseRoutingVPN1")
        }
    }
}

#Preview {
    RoutingVPN1View()
}
