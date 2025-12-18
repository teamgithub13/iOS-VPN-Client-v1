import SwiftUI

struct PresetsVPN1View: View {
    
    var dismissVPN1Action: (() -> Void)?
    var createRulesVPN1Action: (() -> Void)?
    
    @State private var rulesVPN1 = [DomainItemVPN1]()
    
    var body: some View {
        VStack(spacing: 25) {
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
                
                Text("Presets")
                    .font(.custom("AlbertSans-SemiBold", size: 28))
            }
            
            Text("Create traffic rules that will help you separate which websites will pass through the VPN")
                .font(.custom("AlbertSans-SemiBold", size: 16))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Button {
                createRulesVPN1Action?()
            } label: {
                Text("Create rules")
                    .font(.custom("AlbertSans-SemiBold", size: 16))
                    .foregroundStyle(.black)
                    .frame(width: 170, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(red: 0.879, green: 0.961, blue: 0.496))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.black, lineWidth: 2)
                    )
            }
            
            VStack(spacing: 15) {
                Text("My rules")
                    .font(.custom("AlbertSans-Regular", size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(rulesVPN1) { itemVPN1 in
                    Text(itemVPN1.textVPN1)
                        .font(.custom("AlbertSans-Regular", size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            if let dataVPN1 = UserDefaults.standard.data(forKey: "DirectlyDomainsVPN1"),
               let decodedItemsVPN1 = try? JSONDecoder().decode([DomainItemVPN1].self, from: dataVPN1) {
                rulesVPN1 += decodedItemsVPN1
            }
            
            if let dataVPN1 = UserDefaults.standard.data(forKey: "ThroughDomainsVPN1"),
               let decodedItemsVPN1 = try? JSONDecoder().decode([DomainItemVPN1].self, from: dataVPN1) {
                rulesVPN1 += decodedItemsVPN1
            }
            
            if let dataVPN1 = UserDefaults.standard.data(forKey: "BlockedDomainsVPN1"),
               let decodedItemsVPN1 = try? JSONDecoder().decode([DomainItemVPN1].self, from: dataVPN1) {
                rulesVPN1 += decodedItemsVPN1
            }
        }
    }
}

#Preview {
    PresetsVPN1View()
}
