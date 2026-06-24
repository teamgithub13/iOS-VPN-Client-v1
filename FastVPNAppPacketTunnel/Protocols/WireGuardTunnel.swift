import Foundation
import NetworkExtension

/// WireGuard is intentionally disabled while VLESS/VMess integration is being finished.
final class WireGuardTunnel {
    init(config: VPNConfiguration, provider: NEPacketTunnelProvider) {}

    func start(completionHandler: @escaping (Error?) -> Void) {
        completionHandler(NSError(
            domain: "WireGuardTunnel",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "WireGuard is temporarily disabled."]
        ))
    }

    func stop(completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
