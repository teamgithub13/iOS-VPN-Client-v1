import Foundation

enum VPNProtocolType: String, Codable {
    case vless = "vless"
    case vmess = "vmess"
    case shadowsocks = "shadowsocks"
    case shadowsocksR = "shadowsocksr"
    case wireguard = "wireguard"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .vless:
            return "VLESS"
        case .vmess:
            return "VMess"
        case .shadowsocks:
            return "Shadowsocks"
        case .shadowsocksR:
            return "ShadowsocksR"
        case .wireguard:
            return "WireGuard"
        case .unknown:
            return "Unknown"
        }
    }
}

