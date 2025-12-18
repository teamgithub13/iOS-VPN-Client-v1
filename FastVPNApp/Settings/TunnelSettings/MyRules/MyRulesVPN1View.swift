import SwiftUI

struct MyRulesVPN1View: View {
    
    var dismissVPN1Action: (() -> Void)?
    
    @State private var nameVPN1 = ""
    
    @State private var directlyDomainsVPN1 = [DomainItemVPN1(textVPN1: "")]
    @State private var throughDomainsVPN1 = [DomainItemVPN1(textVPN1: "")]
    @State private var blockedDomainsVPN1 = [DomainItemVPN1(textVPN1: "")]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
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
                
                VStack {
                    Text("Give the rule a recognizable name.")
                        .font(.custom("AlbertSans-Regular", size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextField("", text: $nameVPN1)
                        .padding()
                        .font(.custom("AlbertSans-Regular", size: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                VStack {
                    Text("Domains that will go directly")
                        .font(.custom("AlbertSans-Regular", size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach($directlyDomainsVPN1) { $itemVPN1 in
                        HStack {
                            TextField("domain:example.com", text: $itemVPN1.textVPN1)
                                .padding()
                                .font(.custom("AlbertSans-Regular", size: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            Button {
                                directlyDomainsVPN1.append(DomainItemVPN1(textVPN1: ""))
                            } label: {
                                Image("addTextFieldVPN1")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 56, height: 56)
                            }
                        }
                    }
                }
                
                VStack {
                    Text("Domains that will go through the proxy")
                        .font(.custom("AlbertSans-Regular", size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach($throughDomainsVPN1) { $itemVPN1 in
                        HStack {
                            TextField("domain:example.com", text: $itemVPN1.textVPN1)
                                .padding()
                                .font(.custom("AlbertSans-Regular", size: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            Button {
                                throughDomainsVPN1.append(DomainItemVPN1(textVPN1: ""))
                            } label: {
                                Image("addTextFieldVPN1")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 56, height: 56)
                            }
                        }
                    }
                }
                
                VStack {
                    Text("Blocked")
                        .font(.custom("AlbertSans-Regular", size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach($blockedDomainsVPN1) { $itemVPN1 in
                        HStack {
                            TextField("domain:example.com", text: $itemVPN1.textVPN1)
                                .padding()
                                .font(.custom("AlbertSans-Regular", size: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            Button {
                                blockedDomainsVPN1.append(DomainItemVPN1(textVPN1: ""))
                            } label: {
                                Image("addTextFieldVPN1")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 56, height: 56)
                            }
                        }
                    }
                }
                
                Button {
                    if !directlyDomainsVPN1.isEmpty {
                        if let dataVPN1 = try? JSONEncoder().encode(directlyDomainsVPN1) {
                            UserDefaults.standard.set(dataVPN1, forKey: "DirectlyDomainsVPN1")
                        }
                    }
                    
                    if !throughDomainsVPN1.isEmpty {
                        if let dataVPN1 = try? JSONEncoder().encode(throughDomainsVPN1) {
                            UserDefaults.standard.set(dataVPN1, forKey: "ThroughDomainsVPN1")
                        }
                    }
                    
                    if !blockedDomainsVPN1.isEmpty {
                        if let dataVPN1 = try? JSONEncoder().encode(blockedDomainsVPN1) {
                            UserDefaults.standard.set(dataVPN1, forKey: "BlockedDomainsVPN1")
                        }
                    }
                    
                    dismissVPN1Action?()
                } label: {
                    Text("Save")
                        .font(.custom("AlbertSans-SemiBold", size: 16))
                        .foregroundStyle(.black)
                        .frame(width: 140, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(red: 0.879, green: 0.961, blue: 0.496))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.black, lineWidth: 2)
                        )
                }
            }
            .padding()
        }
        .onTapGesture {
            UIApplication.shared.hideKeyboardVPN1()
        }
    }
}

struct DomainItemVPN1: Identifiable, Codable {
    var id = UUID()
    var textVPN1: String = ""
}

#Preview {
    MyRulesVPN1View()
}
