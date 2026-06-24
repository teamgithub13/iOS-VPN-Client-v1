import Foundation
import NetworkExtension

/// Shadowsocks is intentionally disabled while VLESS/VMess integration is being finished.
final class ShadowsocksTunnel {
    init(config: VPNConfiguration) {}

    func start(packetFlow: NEPacketTunnelFlow, completionHandler: @escaping (Error?) -> Void) {
        completionHandler(NSError(
            domain: "ShadowsocksTunnel",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Shadowsocks is temporarily disabled."]
        ))
    }

    func stop() {}
}
