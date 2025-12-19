import Foundation

struct VPNConfiguration: Codable {
    let protocolType: VPNProtocolType
    
    // Общие параметры
    let address: String
    let port: Int
    let remark: String?
    
    // VLESS/VMess параметры
    let uuid: String?
    let security: String?
    let sni: String?
    let alpn: String?
    let fingerprint: String?
    let type: String?
    let flow: String?
    let encryption: String?
    
    // Shadowsocks параметры
    let method: String?  // метод шифрования
    let password: String?
    
    // WireGuard параметры
    let privateKey: String?
    let publicKey: String?
    let presharedKey: String?
    let dns: String?
    let allowedIPs: String?
    let endpoint: String?
    
    // VMess дополнительные параметры
    let alterId: Int?
    let network: String?
    let tls: String?
    
    init(
        protocolType: VPNProtocolType,
        address: String,
        port: Int,
        remark: String? = nil,
        uuid: String? = nil,
        security: String? = nil,
        sni: String? = nil,
        alpn: String? = nil,
        fingerprint: String? = nil,
        type: String? = nil,
        flow: String? = nil,
        encryption: String? = nil,
        method: String? = nil,
        password: String? = nil,
        privateKey: String? = nil,
        publicKey: String? = nil,
        presharedKey: String? = nil,
        dns: String? = nil,
        allowedIPs: String? = nil,
        endpoint: String? = nil,
        alterId: Int? = nil,
        network: String? = nil,
        tls: String? = nil
    ) {
        self.protocolType = protocolType
        self.address = address
        self.port = port
        self.remark = remark
        self.uuid = uuid
        self.security = security
        self.sni = sni
        self.alpn = alpn
        self.fingerprint = fingerprint
        self.type = type
        self.flow = flow
        self.encryption = encryption
        self.method = method
        self.password = password
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.presharedKey = presharedKey
        self.dns = dns
        self.allowedIPs = allowedIPs
        self.endpoint = endpoint
        self.alterId = alterId
        self.network = network
        self.tls = tls
    }
}
