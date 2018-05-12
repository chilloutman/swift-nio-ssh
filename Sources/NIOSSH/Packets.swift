
// uint32    packet_length
// byte      padding_length
// byte[n1]  payload; n1 = packet_length - padding_length - 1
// byte[n2]  random padding; n2 = padding_length
// byte[m]   mac (Message Authentication Code - MAC); m = mac_length
//
// packet_length
// The length of the packet in bytes, not including 'mac' or the
// 'packet_length' field itself.
//
// padding_length
// Length of 'random padding' (bytes).
//
// payload
// The useful contents of the packet.  If compression has been
// negotiated, this field is compressed.  Initially, compression
// MUST be "none".
//
// random padding
// Arbitrary-length padding, such that the total length of
// (packet_length || padding_length || payload || random padding)
// is a multiple of the cipher block size or 8, whichever is
// larger.  There MUST be at least four bytes of padding.  The
// padding SHOULD consist of random bytes.  The maximum amount of
// padding is 255 bytes.
//
// mac
// Message Authentication Code.  If message authentication has
// been negotiated, this field contains the MAC bytes.  Initially,
// the MAC algorithm MUST be "none".

public struct PacketHeader {
    static let headerLength: Int = MemoryLayout<UInt32>.size + MemoryLayout<UInt8>.size
    
    let packetLength: UInt32
    let paddingLength: UInt8
    
    init(packetLength: UInt32, paddingLength: UInt8) {
        self.packetLength = packetLength
        self.paddingLength = paddingLength
    }
    
    init(payloadLength: UInt32, paddingLength: UInt8) {
        self.init(packetLength: UInt32(1) + UInt32(paddingLength) + payloadLength, paddingLength: paddingLength)
    }
}

extension PacketHeader {
    func payloadLength() -> Int {
        return Int(packetLength) - Int(paddingLength) - 1
    }

    func bodyLength(macAlgorithm: MACAlgorithm) -> Int {
        return Int(packetLength) - 1 - Int(macAlgorithm.length)
    }
}

public struct Packet {
    let header: PacketHeader
    let payload: [UInt8]
    let padding: [UInt8]
    let mac: [UInt8]
    
    init(payload: [UInt8], padding: [UInt8], mac: [UInt8]) {
        header = PacketHeader(payloadLength: UInt32(payload.count), paddingLength: UInt8(padding.count))
        self.payload = payload
        self.padding = padding
        self.mac = mac
    }
}

extension Packet: Equatable {
    public static func ==(lhs: Packet, rhs: Packet) -> Bool {
        return lhs.payload == rhs.payload
    }
}

// byte         SSH_MSG_KEXINIT
// byte[16]     cookie (random bytes)
// name-list    kex_algorithms
// name-list    server_host_key_algorithms
// name-list    encryption_algorithms_client_to_server
// name-list    encryption_algorithms_server_to_client
// name-list    mac_algorithms_client_to_server
// name-list    mac_algorithms_server_to_client
// name-list    compression_algorithms_client_to_server
// name-list    compression_algorithms_server_to_client
// name-list    languages_client_to_server
// name-list    languages_server_to_client
// boolean      first_kex_packet_follows
// uint32       0 (reserved for future extension)
struct AlgorithmNegotiation {
    let sshMessageKexInit: UInt8
    let cookie: [UInt8]
    let serverHostKeyAlgorithms: [Algorithm]
    let clientToServer: Communication
    let serverToClient: Communication
    let keyExchange: KeyExchange?
}

struct Communication {
    let encryption: [Algorithm]
    let mac: [MACAlgorithm]
    let compression: [Algorithm]
    let languages: [String]
}

struct KeyExchange {
    
}

//extension Array where Element == UInt8 {
//    init(bytesOf bytes: UInt32) {
//        self.init(repeating: 0, count: 32/8)
//        withUnsafeMutableBytes {
//            $0.storeBytes(of: bytes, as: UInt32.self)
//        }
//    }
//}

