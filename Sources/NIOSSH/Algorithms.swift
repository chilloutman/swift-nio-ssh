
protocol Algorithm {
    var name: String { get }
}

enum MACAlgorithm: String {
    case hmacSha1 = "hmac-sha1"
    case hmacSha196 = "hmac-sha1-96"
    case none = "none"
    
    var digestLength: UInt8 {
        switch self {
        case .hmacSha1: return 20
        case .hmacSha196: return 12
        case .none: return 0
        }
    }
    
    var keyLength: UInt8 {
        switch self {
        case .hmacSha1: return 20
        case .hmacSha196: return 20
        case .none: return 0
        }
    }
    
    var length: UInt8 {
        return digestLength + keyLength
    }
}

extension MACAlgorithm: Algorithm { }

extension Algorithm where Self: RawRepresentable, Self.RawValue == String {
    var name: String {
        return rawValue
    }
}

