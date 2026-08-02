import Foundation

/// Хранилище накопительной статистики трафика (Traffic volume directly).
///
/// После каждого отключения VPN добавляет случайную прибавку к накопленным суммам,
/// имитируя расход трафика за сессию (5/3 МБ за ~30 мин, 15/9 МБ за час и т.д.).
/// Значения сохраняются в UserDefaults и растут между сессиями.
final class StatisticsRepository {

    static let shared = StatisticsRepository()

    private let defaults = UserDefaults.standard
    private let directDownloadKey = "com.fastvpn.stats.directDownload"
    private let directUploadKey = "com.fastvpn.stats.directUpload"
    private let proxyDownloadKey = "com.fastvpn.stats.proxyDownload"
    private let proxyUploadKey = "com.fastvpn.stats.proxyUpload"

    private init() {}

    // MARK: - Proxy traffic (из VPN-сессий, накапливается после каждого отключения)

    var proxyDownloadBytes: Int64 {
        Int64(defaults.integer(forKey: proxyDownloadKey))
    }

    var proxyUploadBytes: Int64 {
        Int64(defaults.integer(forKey: proxyUploadKey))
    }

    /// Добавляет накопленный за сессию трафик (received/sent) к Proxy traffic volume.
    func addSessionTraffic(download: Int64, upload: Int64) {
        defaults.set(proxyDownloadBytes + download, forKey: proxyDownloadKey)
        defaults.set(proxyUploadBytes + upload, forKey: proxyUploadKey)
    }

    // MARK: - Direct traffic (накапливается после каждого подключения)

    var directDownloadBytes: Int64 {
        Int64(defaults.integer(forKey: directDownloadKey))
    }

    var directUploadBytes: Int64 {
        Int64(defaults.integer(forKey: directUploadKey))
    }

    /// Добавляет случайную прибавку к накопленным суммам (вызывается при отключении VPN).
    /// Имитирует расход трафика за сессию: download > upload, диапазон 3–20 МБ.
    func addRandomSessionTraffic() {
        let downloadMB = Int64.random(in: 5...20)
        let uploadMB = Int64.random(in: 3...12)
        let currentDownload = directDownloadBytes
        let currentUpload = directUploadBytes
        defaults.set(currentDownload + downloadMB * 1_048_576, forKey: directDownloadKey)
        defaults.set(currentUpload + uploadMB * 1_048_576, forKey: directUploadKey)
    }

    /// Сброс накопленной статистики (если понадобится кнопка «очистить»).
    func reset() {
        defaults.removeObject(forKey: directDownloadKey)
        defaults.removeObject(forKey: directUploadKey)
        defaults.removeObject(forKey: proxyDownloadKey)
        defaults.removeObject(forKey: proxyUploadKey)
    }
}
