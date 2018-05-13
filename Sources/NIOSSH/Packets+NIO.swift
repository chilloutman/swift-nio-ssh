
import NIO

protocol ByteBufferWritable {
    func write(to buffer: inout ByteBuffer)
}

protocol ByteBufferReadable {
    init?(readFrom buffer: inout ByteBuffer)
}

typealias ByteBufferCodable = ByteBufferReadable & ByteBufferWritable

/// Network byte order
private let endianness = Endianness.big

extension PacketHeader: ByteBufferReadable {
    init?(readFrom buffer: inout ByteBuffer) {
        guard buffer.readableBytes >= PacketHeader.headerLength else {
            return nil
        }

        guard let packetLength: UInt32 = buffer.readInteger(endianness: endianness) else { return nil }
        print("packetLength = \(packetLength)")

        guard let paddingLength: UInt8 = buffer.readInteger(endianness: endianness) else { return nil }
        print("paddingLength = \(paddingLength)")
        
        self.init(packetLength: packetLength, paddingLength: paddingLength)
    }
}

extension Packet: ByteBufferCodable {
    init?(readFrom buffer: inout ByteBuffer) {
        guard let header = PacketHeader(readFrom: &buffer) else { return nil }
        guard let payload = buffer.readBytes(length: Int(header.payloadLength())) else { return nil }
        guard let padding = buffer.readBytes(length: Int(header.paddingLength))  else { return nil }

        self.packetLength = header.packetLength
        self.paddingLength = header.paddingLength
        self.payload = payload
        self.padding = padding
        self.mac = []
    }

    init?(header: PacketHeader, readFrom buffer: inout ByteBuffer, macAlgorithm: MACAlgorithm) {
        guard let payload = buffer.readBytes(length: Int(header.payloadLength())) else { return nil }
        print("payload = \(summaryDescription(payload))")
        guard let padding = buffer.readBytes(length: Int(header.paddingLength))  else { return nil }
        print("padding = \(summaryDescription(padding))")
        guard let mac = buffer.readBytes(length: Int(macAlgorithm.length)) else { return nil }
        print("mac = \(mac)")

        self.packetLength = header.packetLength
        self.paddingLength = header.paddingLength
        self.payload = payload
        self.padding = padding
        self.mac = mac
    }
    
    func write(to buffer: inout ByteBuffer) {
        buffer.write(integer: packetLength, endianness: endianness)
        buffer.write(integer: paddingLength)
        buffer.write(bytes: payload)
        buffer.write(bytes: padding)
        buffer.write(bytes: mac)
    }
}

extension NameList: ByteBufferCodable {
    init?(readFrom buffer: inout ByteBuffer) {
        guard let length: UInt32 = buffer.readInteger(endianness: endianness) else { return nil }
        guard let nameList = buffer.readString(length: Int(length)) else { return nil }

        self.length = length
        self.names = nameList.split(separator: NameList.separator).map(String.init)
    }

    func write(to buffer: inout ByteBuffer) {
        buffer.write(integer: length, endianness: endianness)
        let nameList = names.joined(separator: String(NameList.separator))
        buffer.write(string: nameList)
    }
}

private func summaryDescription<T>(_ array: [T]) -> String {
    return "\(type(of: array))[\(array.count)]"
}
