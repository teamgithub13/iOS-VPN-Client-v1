import Foundation

enum VPNProtocolType: String, Codable {
    case vless = "vless"
    case vmess = "vmess"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .vless:
            return "VLESS"
        case .vmess:
            return "VMess"
        case .unknown:
            return "Unknown"
        }
    }
}
