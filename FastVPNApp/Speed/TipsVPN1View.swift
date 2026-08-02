import SwiftUI

/// Модель совета для экрана Tips.
/// `id` — стабильный (вычисляется из текста), чтобы избранное сохранялось между сессиями.
struct Tip: Identifiable {
    let id: String
    let text: String
    var isFavorite: Bool

    init(text: String, isFavorite: Bool = false) {
        self.id = text
        self.text = text
        self.isFavorite = isFavorite
    }
}

struct TipsVPN1View: View {

    var dismissVPN1Action: (() -> Void)?

    /// Ключ в UserDefaults для хранения избранных советов (по тексту)
    private let favoritesKey = "com.fastvpn.tips.favorites"

    @State private var tips: [Tip] = {
        let rawTips = [
            "Restart your router to refresh your connection.",
            "Move closer to your Wi-Fi router for a stronger signal.",
            "Reduce the number of devices using your network.",
            "Switch between 2.4 GHz and 5 GHz Wi-Fi bands for better stability.",
            "Close background apps that may consume bandwidth.",
            "Try connecting with an Ethernet cable for maximum speed.",
            "Disable VPN temporarily if you need the fastest raw speed.",
            "Change your VPN server location for better performance.",
            "Clear your device’s network settings if speeds seem unusually low.",
            "Avoid running large downloads during your speed test.",
            "Select a nearby test server for the most accurate results.",
            "Update your router’s firmware to improve connectivity.",
            "Reboot your device to fix potential network glitches.",
            "Check with your ISP if your current plan meets your speed needs.",
            "Run multiple speed tests at different times to see real performance trends."
        ]
        // Загружаем сохранённые избранные тексты
        let saved = UserDefaults.standard.stringArray(forKey: "com.fastvpn.tips.favorites") ?? []
        return rawTips.map { Tip(text: $0, isFavorite: saved.contains($0)) }
    }()

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
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                tip.wrappedValue.isFavorite.toggle()
                persistFavorites()
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text(tip.wrappedValue.text)
                    .font(.custom("AlbertSans-Regular", size: 15))
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: tip.wrappedValue.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 22))
                    .foregroundStyle(tip.wrappedValue.isFavorite ? .red : .gray)
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
        .buttonStyle(.plain)
    }

    // MARK: - Persistence

    /// Сохраняет тексты избранных советов в UserDefaults.
    private func persistFavorites() {
        let favorites = tips.filter { $0.isFavorite }.map { $0.text }
        UserDefaults.standard.set(favorites, forKey: favoritesKey)
    }
}

#Preview {
    TipsVPN1View()
}
