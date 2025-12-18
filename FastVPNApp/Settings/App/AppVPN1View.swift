import SwiftUI

struct AppVPN1View: View {
    
    var dismissVPN1Action: (() -> Void)?
    var privacyVPN1Action: (() -> Void)?
    var termsVPN1Action: (() -> Void)?
    var supportVPN1Action: (() -> Void)?
    
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
                
                Text("App")
                    .font(.custom("AlbertSans-SemiBold", size: 28))
            }
            
            HStack {
                Image("privacyVPN1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                
                Text("Privacy Policy")
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
                privacyVPN1Action?()
            }
            
            HStack {
                Image("termsVPN1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                
                Text("Terms of Use")
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
                termsVPN1Action?()
            }
            
            HStack {
                Image("supportVPN1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                
                Text("Support")
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
                supportVPN1Action?()
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    AppVPN1View()
}
