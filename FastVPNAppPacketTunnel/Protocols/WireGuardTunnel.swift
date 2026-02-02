import Foundation
import NetworkExtension
import WireGuardKit

/// Обертка для WireGuard туннеля
final class WireGuardTunnel {
    private let config: VPNConfiguration
    private let adapter: WireGuardAdapter
    
    init(config: VPNConfiguration, provider: NEPacketTunnelProvider) {
        self.config = config
        self.adapter = WireGuardAdapter(with: provider, logHandler: { level, message in
            NSLog("[WireGuard][\(level)] \(message)")
        })
    }
    
    /// Запускает WireGuard туннель
    func start(completionHandler: @escaping (Error?) -> Void) {
        do {
            let tunnelConfiguration = try Self.buildTunnelConfiguration(from: config)
            adapter.start(tunnelConfiguration: tunnelConfiguration, completionHandler: completionHandler)
        } catch {
            completionHandler(error)
        }
    }
    
    /// Останавливает туннель
    func stop(completionHandler: @escaping () -> Void) {
        adapter.stop { _ in
            completionHandler()
        }
    }

    private static func buildTunnelConfiguration(from config: VPNConfiguration) throws -> TunnelConfiguration {
        guard let privateKey = config.privateKey,
              let publicKey = config.publicKey else {
            throw NSError(domain: "WireGuardTunnel", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Отсутствуют ключи WireGuard (private/public)."])
        }

        let interfaceAddress = sanitized(config.interfaceAddress) ?? "10.0.0.2/32"
        let allowedIPs = sanitized(config.allowedIPs) ?? "0.0.0.0/0"
        let endpoint = buildEndpoint(from: config)

        var wgConfig = """
        [Interface]
        PrivateKey = \(privateKey)
        Address = \(interfaceAddress)
        """

        if let dns = sanitized(config.dns) {
            wgConfig += "\nDNS = \(dns)"
        }

        wgConfig += """

        [Peer]
        PublicKey = \(publicKey)
        Endpoint = \(endpoint)
        AllowedIPs = \(allowedIPs)
        """

        if let presharedKey = sanitized(config.presharedKey) {
            wgConfig += "\nPresharedKey = \(presharedKey)"
        }

        return try TunnelConfiguration(fromWgQuickConfig: wgConfig)
    }

    private static func buildEndpoint(from config: VPNConfiguration) -> String {
        if let endpoint = sanitized(config.endpoint) {
            if endpoint.contains(":") {
                return endpoint
            }
            return "\(endpoint):\(config.port)"
        }

        return "\(config.address):\(config.port)"
    }

    private static func sanitized(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }
}
