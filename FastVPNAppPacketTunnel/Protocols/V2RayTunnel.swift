import Foundation
import NetworkExtension
import SwiftyXrayKit

/// VLESS/VMess tunnel powered by SwiftyXrayKit.
final class V2RayTunnel {
    private let config: VPNConfiguration
    private var tunnel: XRayTunnel?
    private let appGroupIdentifier = "group.com.gooseberry.colander"

    init(config: VPNConfiguration) {
        self.config = config
    }

    func start(packetFlow: NEPacketTunnelFlow, completionHandler: @escaping (Error?) -> Void) {
        do {
            let runtime = try prepareRuntimeDirectory()
            let intermediateConfig = try buildIntermediateConfig()
            let tunnel = XRayTunnel(packetFlow: packetFlow)
            self.tunnel = tunnel

            Task {
                do {
                    try await tunnel.run(
                        dataDir: runtime.dataDirectory,
                        config: intermediateConfig,
                        finalConfigPath: runtime.configPath
                    )
                    completionHandler(nil)
                } catch {
                    completionHandler(error)
                }
            }
        } catch {
            completionHandler(error)
        }
    }

    func stop() {
        let tunnel = tunnel
        self.tunnel = nil
        Task {
            await tunnel?.stop()
        }
    }

    private func prepareRuntimeDirectory() throws -> (dataDirectory: URL, configPath: URL) {
        let baseDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
            ?? FileManager.default.temporaryDirectory
        let runtimeDirectory = baseDirectory.appendingPathComponent("xray-runtime", isDirectory: true)
        let dataDirectory = runtimeDirectory.appendingPathComponent("data", isDirectory: true)
        let configPath = runtimeDirectory.appendingPathComponent("config.json", isDirectory: false)

        try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)

        return (dataDirectory, configPath)
    }

    private func buildIntermediateConfig() throws -> XrayIntermediateConfig {
        if let sourceURL = config.sourceURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           !sourceURL.isEmpty {
            return .url(sourceURL)
        }

        let dictionary = try buildFallbackJSONDictionary()
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        guard let json = String(data: data, encoding: .utf8) else {
            throw V2RayTunnelError.invalidFallbackConfiguration
        }

        return .json(json)
    }

    private func buildFallbackJSONDictionary() throws -> [String: Any] {
        guard let uuid = config.uuid?.trimmingCharacters(in: .whitespacesAndNewlines),
              !uuid.isEmpty else {
            throw V2RayTunnelError.missingUUID
        }

        let protocolName = config.protocolType == .vless ? "vless" : "vmess"
        var user: [String: Any] = ["id": uuid]

        if protocolName == "vless" {
            user["encryption"] = config.encryption ?? "none"
            if let flow = config.flow, !flow.isEmpty {
                user["flow"] = flow
            }
        } else {
            user["alterId"] = config.alterId ?? 0
            user["security"] = config.security ?? "auto"
        }

        var streamSettings: [String: Any] = [
            "network": config.network ?? config.type ?? "tcp"
        ]

        let security = config.security ?? config.tls
        if let security, security != "none", !security.isEmpty {
            streamSettings["security"] = security
            var tlsSettings: [String: Any] = [:]
            if let sni = config.sni, !sni.isEmpty {
                tlsSettings["serverName"] = sni
            }
            if let alpn = config.alpn, !alpn.isEmpty {
                tlsSettings["alpn"] = alpn.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }
            if !tlsSettings.isEmpty {
                streamSettings["tlsSettings"] = tlsSettings
            }
        }

        return [
            "log": [
                "loglevel": "warning"
            ],
            "outbounds": [[
                "protocol": protocolName,
                "settings": [
                    "vnext": [[
                        "address": config.address,
                        "port": config.port,
                        "users": [user]
                    ]]
                ],
                "streamSettings": streamSettings,
                "tag": "proxy"
            ]],
            "routing": [
                "domainStrategy": "AsIs",
                "rules": []
            ]
        ]
    }
}

private enum V2RayTunnelError: LocalizedError {
    case missingUUID
    case invalidFallbackConfiguration

    var errorDescription: String? {
        switch self {
        case .missingUUID:
            return "Missing UUID for VLESS/VMess configuration."
        case .invalidFallbackConfiguration:
            return "Failed to build fallback Xray JSON configuration."
        }
    }
}
