import Foundation
import NIO

extension PacketHeader {
    init?(readFrom buffer: inout ByteBuffer) {
        guard let packetLength = buffer.readInteger(endianness: .big, as: UInt32.self) else { return nil }
        print("packetLength = \(packetLength)")
        guard let paddingLength: UInt8 = buffer.readInteger() else { return nil }
        print("paddingLength = \(paddingLength)")
        
        self.init(packetLength: packetLength, paddingLength: paddingLength)
    }
}

extension Packet {
    init?(header: PacketHeader, readFrom buffer: inout ByteBuffer, macAlgorithm: MACAlgorithm) {
        guard let payload = buffer.readBytes(length: Int(header.payloadLength())) else { return nil }
        print("payload = \(summaryDescription(payload))")
        guard let padding = buffer.readBytes(length: Int(header.paddingLength))  else { return nil }
        print("padding = \(summaryDescription(padding))")
        guard let mac = buffer.readBytes(length: Int(macAlgorithm.length)) else { return nil }
        print("mac = \(mac)")

        self.header = header
        self.payload = payload
        self.padding = padding
        self.mac = mac
    }
    
    func write(to buffer: inout ByteBuffer) {
        buffer.write(integer: header.packetLength, endianness: .big, as: UInt32.self)
        buffer.write(integer: header.paddingLength)
        buffer.write(bytes: payload)
        buffer.write(bytes: padding)
        buffer.write(bytes: mac)
    }
}

private func summaryDescription<T>(_ array: [T]) -> String {
    return "\(type(of: array))[\(array.count)]"
}
