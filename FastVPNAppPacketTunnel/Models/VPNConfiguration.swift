import Foundation

struct VPNConfiguration: Codable {
    let protocolType: VPNProtocolType
    let sourceURL: String?

    // Общие параметры
    let address: String
    let port: Int
    var remark: String?

    // VLESS/VMess параметры
    let uuid: String?
    let security: String?
    let sni: String?
    let alpn: String?
    let fingerprint: String?
    let type: String?
    let flow: String?
    let encryption: String?

    // VMess дополнительные параметры
    let alterId: Int?
    let network: String?
    let tls: String?

    init(
        protocolType: VPNProtocolType,
        sourceURL: String? = nil,
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
        alterId: Int? = nil,
        network: String? = nil,
        tls: String? = nil
    ) {
        self.protocolType = protocolType
        self.sourceURL = sourceURL
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
        self.alterId = alterId
        self.network = network
        self.tls = tls
    }
}
