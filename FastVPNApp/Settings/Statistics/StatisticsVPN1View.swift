import SwiftUI

struct StatisticsVPN1View: View {
    
    var dismissVPN1Action: (() -> Void)?
    
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
                
                Text("Statistics")
                    .font(.custom("AlbertSans-SemiBold", size: 28))
            }
            
            VStack {
                Text("Proxy traffic volume")
                    .font(.custom("AlbertSans-Regular", size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 25) {
                    HStack {
                        Text("Download")
                            .font(.custom("AlbertSans-Regular", size: 16))
                        
                        Spacer()
                        
                        Text("0b")
                            .font(.custom("AlbertSans-Regular", size: 16))
                    }
                    
                    HStack {
                        Text("Upload")
                            .font(.custom("AlbertSans-Regular", size: 16))
                        
                        Spacer()
                        
                        Text("0b")
                            .font(.custom("AlbertSans-Regular", size: 16))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.05), radius: 30)
                )
            }
            
            VStack {
                Text("Traffic volume directly")
                    .font(.custom("AlbertSans-Regular", size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 25) {
                    HStack {
                        Text("Download")
                            .font(.custom("AlbertSans-Regular", size: 16))
                        
                        Spacer()
                        
                        Text("0b")
                            .font(.custom("AlbertSans-Regular", size: 16))
                    }
                    
                    HStack {
                        Text("Upload")
                            .font(.custom("AlbertSans-Regular", size: 16))
                        
                        Spacer()
                        
                        Text("0b")
                            .font(.custom("AlbertSans-Regular", size: 16))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.05), radius: 30)
                )
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    StatisticsVPN1View()
}
