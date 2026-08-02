import SwiftUI

struct StatisticsVPN1View: View {

    var dismissVPN1Action: (() -> Void)?

    var body: some View {
        VStack(spacing: 25) {
            header

            // Proxy traffic volume — накопленный трафик из всех VPN-сессий
            VStack(spacing: 8) {
                Text("Proxy traffic volume")
                    .font(.custom("AlbertSans-SemiBold", size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 25) {
                    HStack {
                        Text("Download")
                            .font(.custom("AlbertSans-Regular", size: 16))
                        Spacer()
                        Text(formatBytes(StatisticsRepository.shared.proxyDownloadBytes))
                            .font(.custom("AlbertSans-Regular", size: 16))
                    }

                    HStack {
                        Text("Upload")
                            .font(.custom("AlbertSans-Regular", size: 16))
                        Spacer()
                        Text(formatBytes(StatisticsRepository.shared.proxyUploadBytes))
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

            // Traffic volume directly — накопительные данные (растут после каждого подключения)
            VStack(spacing: 8) {
                Text("Traffic volume directly")
                    .font(.custom("AlbertSans-Regular", size: 16))
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 25) {
                    HStack {
                        Text("Download")
                            .font(.custom("AlbertSans-Regular", size: 16))
                        Spacer()
                        Text(formatBytes(StatisticsRepository.shared.directDownloadBytes))
                            .font(.custom("AlbertSans-Regular", size: 16))
                    }

                    HStack {
                        Text("Upload")
                            .font(.custom("AlbertSans-Regular", size: 16))
                        Spacer()
                        Text(formatBytes(StatisticsRepository.shared.directUploadBytes))
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

            Text("Statistics")
                .font(.custom("AlbertSans-SemiBold", size: 28))
        }
    }

    // MARK: - Formatting

    /// Форматирует байты в читаемый вид (KB, MB, GB). Для нуля — «0 KB».
    private func formatBytes(_ bytes: Int64) -> String {
        if bytes <= 0 {
            return "0 KB"
        }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .binary
        formatter.zeroPadsFractionDigits = false
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    StatisticsVPN1View()
}
