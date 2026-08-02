import SwiftUI

struct TunnelSettingsVPN1View: View {
    
    var dismissVPN1Action: (() -> Void)?
    var presetsVPN1Action: (() -> Void)?
    var routingVPN1Action: (() -> Void)?
    var onDemandVPN1Action: (() -> Void)?
    var pingVPN1Action: (() -> Void)?
    
    @State private var muxVPN1 = false
    @State private var allowLanVPN1 = false
    @State private var typeIpVPN1 = ""
    @State private var showTypeIpVPN1 = false
    
    private let typeIpsVPN1 = ["IPv4", "IPv6", "IPv4&iPv6"]
    
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
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
                        
                        Text("Tunnel settings")
                            .font(.custom("AlbertSans-SemiBold", size: 28))
                    }
                    
                    HStack(spacing: 20) {
                        Image("presetsVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                        
                        Text("Presets")
                            .font(.custom("AlbertSans-SemiBold", size: 20))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image("onbForwardVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 32)
                    }
                    .padding()
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.05), radius: 30)
                    )
                    .onTapGesture {
                        presetsVPN1Action?()
                    }
                    
                    HStack(spacing: 20) {
                        Image("muxVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                        
                        Text("Mux")
                            .font(.custom("AlbertSans-SemiBold", size: 20))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(muxVPN1 ? "switchOnVPN1" : "switchOffVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 32)
                            .onTapGesture {
                                muxVPN1.toggle()
                                UserDefaults.standard.set(muxVPN1, forKey: "MuxVPN1")
                            }
                    }
                    .padding()
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.05), radius: 30)
                    )
                    
                    HStack(spacing: 20) {
                        Image("routingVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                        
                        Text("Routing")
                            .font(.custom("AlbertSans-SemiBold", size: 20))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image("onbForwardVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 32)
                    }
                    .padding()
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.05), radius: 30)
                    )
                    .onTapGesture {
                        routingVPN1Action?()
                    }
                    
                    HStack(spacing: 20) {
                        Image("typeIpVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                        
                        Text("Type IP")
                            .font(.custom("AlbertSans-SemiBold", size: 20))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image("arrowDownVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 32)
                    }
                    .padding()
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.05), radius: 30)
                    )
                    .onTapGesture {
                        showTypeIpVPN1 = true
                    }
                    
                    HStack(spacing: 20) {
                        Image("onDemandVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                        
                        Text("On Demand")
                            .font(.custom("AlbertSans-SemiBold", size: 20))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image("onbForwardVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 32)
                    }
                    .padding()
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.05), radius: 30)
                    )
                    .onTapGesture {
                        onDemandVPN1Action?()
                    }
                    
                    HStack(spacing: 20) {
                        Image("allowLanVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                        
                        Text("Allow LAN\nconnections")
                            .font(.custom("AlbertSans-SemiBold", size: 20))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(allowLanVPN1 ? "switchOnVPN1" : "switchOffVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 32)
                            .onTapGesture {
                                allowLanVPN1.toggle()
                                UserDefaults.standard.set(allowLanVPN1, forKey: "AllowLanVPN1")
                            }
                    }
                    .padding()
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.05), radius: 30)
                    )
                    
                    HStack(spacing: 20) {
                        Image("pingVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                        
                        Text("Ping")
                            .font(.custom("AlbertSans-SemiBold", size: 20))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image("arrowDownVPN1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 32)
                    }
                    .padding()
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.05), radius: 30)
                    )
                    .onTapGesture {
                        pingVPN1Action?()
                    }
                }
                .padding()
            }
            
            if showTypeIpVPN1 {
                ZStack {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            showTypeIpVPN1 = false
                        }
                    
                    VStack {
                        Spacer()
                        
                        VStack {
                            HStack {
                                Spacer()

                                Button {
                                    withAnimation {
                                        showTypeIpVPN1 = false
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .frame(width: 24, height: 24)
                                        .foregroundStyle(Color.black)
                                }

                            }
                            ForEach(typeIpsVPN1, id: \.self) { itemVPN1 in
                                HStack {
                                    Image(typeIpVPN1 == itemVPN1 ? "circleFilledVPN1" : "circleEmptyVPN1")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                    
                                    Text(itemVPN1)
                                        .font(.custom("AlbertSans-Regular", size: 16))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .onTapGesture {
                                    typeIpVPN1 = itemVPN1
                                    UserDefaults.standard.set(typeIpVPN1, forKey: "TypeIpVPN1")
                                    showTypeIpVPN1 = false
                                }
                                
                                Divider()
                            }
                        }
                        .padding()
                        .padding(.bottom, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white)
                        )
                    }
                    .edgesIgnoringSafeArea(.bottom)
                }
            }
        }
        .onAppear {
            muxVPN1 = UserDefaults.standard.bool(forKey: "MuxVPN1")
            allowLanVPN1 = UserDefaults.standard.bool(forKey: "AllowLanVPN1")
            typeIpVPN1 = UserDefaults.standard.string(forKey: "TypeIpVPN1") ?? ""
        }
    }
}

#Preview {
    TunnelSettingsVPN1View()
}
