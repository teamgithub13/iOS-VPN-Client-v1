import SwiftUI

struct ServiceVPN1View: View {
    
    @State private var isConnectedVPN1 = false
    
    var body: some View {
        VStack(spacing: 20) {
            Button {
                
            } label: {
                Image(isConnectedVPN1 ? "vpnOnVPN1" : "vpnOffVPN1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
            }
            
            HStack {
                VStack(spacing: 15) {
                    Text("Received")
                        .font(.custom("AlbertSans-SemiBold", size: 14))
                        .frame(maxWidth: .infinity)
                    
                    Text("0b")
                        .font(.custom("AlbertSans-Regular", size: 14))
                }
                
                if isConnectedVPN1 {
                    VStack(spacing: 15) {
                        Text("Connected")
                            .font(.custom("AlbertSans-SemiBold", size: 14))
                            .frame(maxWidth: .infinity)
                        
                        Text("0b")
                            .font(.custom("AlbertSans-Regular", size: 16))
                    }
                }
                
                VStack(spacing: 15) {
                    Text("Sent")
                        .font(.custom("AlbertSans-SemiBold", size: 14))
                        .frame(maxWidth: .infinity)
                    
                    Text("0b")
                        .font(.custom("AlbertSans-Regular", size: 16))
                }
            }
            
            VStack(spacing: 30) {
                Text("List is empty")
                    .font(.custom("AlbertSans-SemiBold", size: 16))
                
                Text("Add configuration")
                    .font(.custom("AlbertSans-SemiBold", size: 20))
                
                VStack(spacing: 15) {
                    Button {
                        
                    } label: {
                        Text("Copy from clipboard")
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
                                    .stroke(.black, lineWidth: 2)
                            )
                    }
                    
                    Button {
                        
                    } label: {
                        Text("Add manually")
                            .font(.custom("AlbertSans-SemiBold", size: 16))
                            .foregroundStyle(.black)
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(.black, lineWidth: 2)
                            )
                    }
                }
            }
            .padding()
            .padding(.vertical)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.1), radius: 30)
            )
        }
        .padding()
    }
}

#Preview {
    ServiceVPN1View()
}
