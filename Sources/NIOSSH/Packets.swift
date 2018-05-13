
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
    let packetLength: UInt32
    let paddingLength: UInt8
    let payload: [UInt8]
    let padding: [UInt8]
    let mac: [UInt8]
    
    init(payload: [UInt8], padding: [UInt8], mac: [UInt8]) {
        self.mac = mac
        self.padding = padding
        self.payload = payload
        paddingLength = UInt8(padding.count)
        packetLength = UInt32(MemoryLayout.size(ofValue: paddingLength)) + UInt32(payload.count) + UInt32(paddingLength)
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

// A string containing a comma-separated list of names.  A name-list
// is represented as a uint32 containing its length (number of bytes
// that follow) followed by a comma-separated list of zero or more
// names.  A name MUST have a non-zero length, and it MUST NOT
// contain a comma (",").  As this is a list of names, all of the
// elements contained are names and MUST be in US-ASCII.  Context may
// impose additional restrictions on the names.  For example, the
// names in a name-list may have to be a list of valid algorithm
// identifiers (see Section 6 below), or a list of [RFC3066] language
// tags.  The order of the names in a name-list may or may not be
// significant.  Again, this depends on the context in which the list
// is used.  Terminating null characters MUST NOT be used, neither
// for the individual names, nor for the list as a whole.
//
// Examples:
//
// value                      representation (hex)
// -----                      --------------------
// (), the empty name-list    00 00 00 00
// ("zlib")                   00 00 00 04 7a 6c 69 62
// ("zlib,none")              00 00 00 09 7a 6c 69 62 2c 6e 6f 6e 65

public struct NameList {
    static let separator = Character(",")
    let length: UInt32
    let names: [String]

    init(names: [String]) {
        self.names = names
        self.length = UInt32(names.map { $0.utf8.count }.reduce(0, +)) + UInt32(names.count)
    }
}
