import SwiftUI

struct PingVPN1View: View {
    
    var dismissVPN1Action: (() -> Void)?
    
    private let protocolsVPN1 = ["TCP", "ICPM", "Proxy HEAD", "Proxy GET"]
    @State private var selectedProtocolVPN1 = ""
    
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
                
                Text("Ping")
                    .font(.custom("AlbertSans-SemiBold", size: 28))
            }
            
            Text("Protocols")
                .font(.custom("AlbertSans-SemiBold", size: 20))
            
            VStack {
                ForEach(protocolsVPN1, id: \.self) { itemVPN1 in
                    HStack {
                        Image(selectedProtocolVPN1 == itemVPN1 ? "circleFilledVPN1" : "circleEmptyVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        
                        Text(itemVPN1)
                            .font(.custom("AlbertSans-Regular", size: 16))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onTapGesture {
                        selectedProtocolVPN1 = itemVPN1
                        UserDefaults.standard.set(selectedProtocolVPN1, forKey: "SelectedProtocolVPN1")
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            selectedProtocolVPN1 = UserDefaults.standard.string(forKey: "SelectedProtocolVPN1") ?? ""
        }
    }
}

#Preview {
    PingVPN1View()
}
