import AppKit

protocol BTRLinkDriverProtocol {
    
}

protocol BTRVocoderDriver {
    var audio: Self { get set }
    var network: (NSObject & BTRLinkDriverProtocol)? { get set }
    var configurationViewController: NSViewController? { get }
    static func driverName() -> String?
    func decodeData(_ data: UnsafeMutableRawPointer?, lastPacket last: Bool)
    func encodeData(_ data: UnsafeMutableRawPointer?, lastPacket last: Bool)
    func start() -> Bool
    func stop()
}

//protocol BTRDV3KVocoder <BTRVocoderDriver> {
//    private(set) var productId = ""
//    private(set) var version = ""
//    override init() {
//}
