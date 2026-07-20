import Foundation
import Combine
import LCLSpeedtest
import os

/// Фаза теста скорости
enum SpeedTestPhase {
    case idle
    case downloading
    case uploading
    case done
}

@MainActor
final class SpeedVPN1ViewModel: ObservableObject {

    private let logger = Logger(subsystem: "com.gooseberry.colander", category: "SpeedTest")

    /// Текущее значение в главном поле (растёт во время теста)
    @Published var liveSpeed: Double = 0
    /// Подпись фазы под числом
    @Published var currentPhase: SpeedTestPhase = .idle
    /// Идёт ли тест
    @Published var isTesting: Bool = false

    /// Финальные результаты (видны после теста)
    @Published var download: Double = 0
    @Published var upload: Double = 0
    @Published var ping: Int = 0
    /// Пришёл ли хоть один колбэк во время download/upload (иначе покажем «N/A»)
    @Published var hasDownload: Bool = false
    @Published var hasUpload: Bool = false

    /// Ошибка (если есть)
    @Published var errorMessage: String?

    /// Ссылка на активный тест-клиент (для отмены). `nonisolated(unsafe)`, т.к.
    /// SpeedTestClient — struct, доступ из cancelTest идёт только пока тест активен.
    private var activeClient: SpeedTestClient?

    /// Последние live-значения (не Published) — используются как финальный
    /// результат, т.к. measurement-колбэки либы часто содержат appInfo == nil.
    private var lastDownloadMbps: Double = 0
    private var lastUploadMbps: Double = 0

    func startTest() {
        guard !isTesting else { return }

        // Сброс
        download = 0
        upload = 0
        ping = 0
        hasDownload = false
        hasUpload = false
        liveSpeed = 0
        lastDownloadMbps = 0
        lastUploadMbps = 0
        errorMessage = nil
        isTesting = true
        currentPhase = .downloading

        // Копируем client в локальную var — либа использует mutating API,
        // а класс @MainActor изолирует свойство. Работаем на локальной копии.
        var client = SpeedTestClient()

        // Live прогресс загрузки
        client.onDownloadProgress = { [weak self] progress in
            let kbps = Self.kbps(from: progress.appInfo)
            Task { @MainActor in
                guard let self = self else { return }
                self.logger.notice("download progress: kbps=\(kbps, privacy: .public), bytes=\(progress.appInfo.numBytes, privacy: .public), elapsed=\(progress.appInfo.elapsedTime, privacy: .public)")
                self.lastDownloadMbps = kbps
                self.liveSpeed = kbps
                self.currentPhase = .downloading
            }
        }

        // Флаг: был ли хоть один download-колбэк (для диагностики)
        var downloadProgressReceived = false
        let originalDownloadProgress = client.onDownloadProgress
        client.onDownloadProgress = { progress in
            downloadProgressReceived = true
            originalDownloadProgress?(progress)
        }

        // Финальный результат загрузки. Логируем ВСЕ measurement (включая server-origin),
        // чтобы понять, доходят ли вообще данные во время download-фазы.
        client.onDownloadMeasurement = { [weak self] measurement in
            Task { @MainActor in
                guard let self = self else { return }
                let origin = measurement.origin?.rawValue ?? "nil"
                let dir = measurement.direction?.rawValue ?? "nil"
                let bytes = measurement.appInfo?.numBytes ?? -1
                let elapsed = measurement.appInfo?.elapsedTime ?? -1
                self.logger.notice("download measurement: origin=\(origin, privacy: .public), dir=\(dir, privacy: .public), bytes=\(bytes, privacy: .public), elapsed=\(elapsed, privacy: .public)")
                // Берём значение из любого client-origin measurement с валидным appInfo
                if let appInfo = measurement.appInfo, measurement.origin == .client {
                    self.lastDownloadMbps = Self.kbps(from: appInfo)
                }
            }
        }

        // Live прогресс отдачи
        client.onUploadProgress = { [weak self] progress in
            let kbps = Self.kbps(from: progress.appInfo)
            Task { @MainActor in
                guard let self = self else { return }
                self.logger.notice("upload progress: kbps=\(kbps, privacy: .public), bytes=\(progress.appInfo.numBytes, privacy: .public), elapsed=\(progress.appInfo.elapsedTime, privacy: .public)")
                self.lastUploadMbps = kbps
                self.liveSpeed = kbps
                self.currentPhase = .uploading
            }
        }

        // Финальный результат отдачи
        client.onUploadMeasurement = { [weak self] measurement in
            guard let appInfo = measurement.appInfo,
                  measurement.origin == .client else { return }
            let kbps = Self.kbps(from: appInfo)
            Task { @MainActor in
                guard let self = self else { return }
                self.logger.notice("upload measurement(client): kbps=\(kbps, privacy: .public)")
                self.lastUploadMbps = kbps
            }
        }

        // Флаг: был ли хоть один upload-колбэк
        var uploadProgressReceived = false
        let originalUploadProgress = client.onUploadProgress
        client.onUploadProgress = { progress in
            uploadProgressReceived = true
            originalUploadProgress?(progress)
        }

        activeClient = client

        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await client.start(with: .downloadAndUpload)
                await MainActor.run {
                    // Финал: берём последние накопленные live-значения.
                    // Если колбэков не было (тест не прошёл через VPN) — оставляем флаг=false,
                    // UI покажет «N/A» вместо 0.
                    self.hasDownload = downloadProgressReceived
                    self.hasUpload = uploadProgressReceived
                    self.logger.notice("test done: lastDownload=\(self.lastDownloadMbps, privacy: .public), lastUpload=\(self.lastUploadMbps, privacy: .public), downloadReceived=\(downloadProgressReceived, privacy: .public), uploadReceived=\(uploadProgressReceived, privacy: .public)")
                    self.download = self.lastDownloadMbps
                    self.upload = self.lastUploadMbps
                    self.isTesting = false
                    self.currentPhase = .done
                    self.activeClient = nil
                    // Пинг либа не отдаёт — рандом 1...3 по ТЗ
                    self.ping = Int.random(in: 1...3)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isTesting = false
                    self.currentPhase = .idle
                    self.activeClient = nil
                }
            }
        }
    }

    /// Пересчёт Mbps из AppInfo (формула из исходников либы: numBytes*8 / elapsedTime).
    /// Используем свой метод, т.к. нативный `MeasurementProgress.mbps` — internal.
    /// Перевод AppInfo → KB/s (килобайты в секунду).
    /// Формула: bytes / elapsedTime(мкс) = bytes/мкс → ×1_000_000 = bytes/с → ÷1024 = KB/s.
    private static func kbps(from appInfo: AppInfo) -> Double {
        let elapsedTime = appInfo.elapsedTime // микросекунды
        guard elapsedTime > 0 else { return 0 }
        let bytesPerSecond = Double(appInfo.numBytes) * 1_000_000 / Double(elapsedTime)
        return bytesPerSecond / 1024.0
    }

    func cancelTest() {
        do {
            try activeClient?.cancel()
        } catch {
            errorMessage = error.localizedDescription
        }
        activeClient = nil
        isTesting = false
        currentPhase = .idle
    }

    /// Текст под главным числом в зависимости от фазы
    var phaseTitle: String {
        switch currentPhase {
        case .idle:
            return "Ready"
        case .downloading:
            return "Download"
        case .uploading:
            return "Upload"
        case .done:
            return "Test complete"
        }
    }

    /// Какое число показывать в главном поле
    var mainDisplayValue: Double {
        switch currentPhase {
        case .idle:
            return 0
        case .downloading, .uploading:
            return liveSpeed
        case .done:
            return download
        }
    }

    /// Прогресс для круговой дуги (0...1). Нормализуем KB/s относительно максимума.
    /// ~10000 KB/s (~80 Mbps) считаем верхней границей для VPN.
    private let maxKbpsForProgress: Double = 10_000

    var progress: Double {
        let value: Double
        switch currentPhase {
        case .idle, .done:
            return 0
        case .downloading:
            value = lastDownloadMbps
        case .uploading:
            value = lastUploadMbps
        }
        return min(max(value / maxKbpsForProgress, 0), 1)
    }
}
