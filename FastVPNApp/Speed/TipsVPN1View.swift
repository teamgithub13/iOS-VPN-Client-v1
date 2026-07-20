import SwiftUI

/// Модель совета для экрана Tips
struct Tip: Identifiable {
    let id = UUID()
    let text: String
    var isFavorite: Bool = false
}

struct TipsVPN1View: View {

    var dismissVPN1Action: (() -> Void)?

    @State private var tips: [Tip] = [
        Tip(text: "Restart your router to refresh your connection."),
        Tip(text: "Move closer to your Wi-Fi router for a stronger signal."),
        Tip(text: "Reduce the number of devices using your network."),
        Tip(text: "Switch between 2.4 GHz and 5 GHz Wi-Fi bands for better stability."),
        Tip(text: "Close background apps that may consume bandwidth."),
        Tip(text: "Try connecting with an Ethernet cable for maximum speed."),
        Tip(text: "Disable VPN temporarily if you need the fastest raw speed."),
        Tip(text: "Change your VPN server location for better performance."),
        Tip(text: "Clear your device’s network settings if speeds seem unusually low."),
        Tip(text: "Avoid running large downloads during your speed test."),
        Tip(text: "Select a nearby test server for the most accurate results."),
        Tip(text: "Update your router’s firmware to improve connectivity."),
        Tip(text: "Reboot your device to fix potential network glitches."),
        Tip(text: "Check with your ISP if your current plan meets your speed needs."),
        Tip(text: "Run multiple speed tests at different times to see real performance trends.")
    ]

    var body: some View {
        VStack(spacing: 20) {
            header

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach($tips) { $tip in
                        tipCard(tip: $tip)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Header

    private var header: some View {
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

            Text("Tips")
                .font(.custom("AlbertSans-SemiBold", size: 28))
        }
        .padding(.top, 8)
    }

    // MARK: - Tip card

    private func tipCard(tip: Binding<Tip>) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(tip.wrappedValue.text)
                .font(.custom("AlbertSans-Regular", size: 15))
                .foregroundStyle(.black)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    tip.wrappedValue.isFavorite.toggle()
                }
            } label: {
                Image(systemName: tip.wrappedValue.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 22))
                    .foregroundStyle(tip.wrappedValue.isFavorite ? .red : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(tip.wrappedValue.isFavorite
                        ? Color(red: 0.879, green: 0.961, blue: 0.496)
                        : Color.gray.opacity(0.2),
                        lineWidth: tip.wrappedValue.isFavorite ? 2 : 1)
        )
    }
}

#Preview {
    TipsVPN1View()
}
