import SwiftUI

struct SettingsVPN1View: View {
    
    var appSettingsVPN1Action: (() -> Void)?
    var tunnelSettingsVPN1Action: (() -> Void)?
    var statisticsVPN1Action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.custom("AlbertSans-SemiBold", size: 28))
            
            HStack {
                Image("appSettingsVPN1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                
                Text("App Settings")
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
                appSettingsVPN1Action?()
            }
            
            HStack {
                Image("tunnelSettingsVPN1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                
                Text("Tunnel Settings")
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
                tunnelSettingsVPN1Action?()
            }
            
            HStack {
                Image("statisticsVPN1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                
                Text("Statistics")
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
                    .shadow(color: .black.opacity(0.1), radius: 20)
            )
            .onTapGesture {
                statisticsVPN1Action?()
            }
            
            Image("settingsVPN1")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: .infinity)
        }
        .padding()
    }
}

#Preview {
    SettingsVPN1View()
}
