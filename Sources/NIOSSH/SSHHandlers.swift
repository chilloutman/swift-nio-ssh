
import NIO

private func trace<T>(_ self: T, function: String = #function) {
    print(" - \(type(of: self)).\(function)")
}

public class ProtocolVersionExchangeHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = ByteBuffer
    
    public func channelActive(ctx: ChannelHandlerContext) {
        trace(self)
        
        var buffer = ctx.channel.allocator.buffer(capacity: identificationString.utf8.count)
        buffer.write(string: identificationString)
        ctx.writeAndFlush(wrapInboundOut(buffer), promise: nil)
    }
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        trace(self)

        var buffer = unwrapInboundIn(data)
        
        guard let serverIdentification = buffer.readString(length: buffer.readableBytes) else {
            ctx.close(promise: nil)
            return
        }
        print(serverIdentification)
        
        _ = ctx.channel.pipeline.remove(handler: self)
    }
    
}

public class PackedDecoder: ByteToMessageDecoder {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = Packet
    
    public var cumulationBuffer: ByteBuffer?
    
    private var header: PacketHeader?
    private var macAlgorithm = MACAlgorithm.none
    
    public func decode(ctx: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        trace(self)

        if header == nil && buffer.readableBytes >= PacketHeader.headerLength {
            header = PacketHeader(readFrom: &buffer)
        }
        
        guard let header = header else {
            throw CodingError(message: "Failed to read packet header")
        }
        
        guard buffer.readableBytes >= header.bodyLength(macAlgorithm: macAlgorithm) else {
            return .needMoreData
        }
        
        guard let packet = Packet(header: header, readFrom: &buffer, macAlgorithm: macAlgorithm) else {
            throw CodingError(message: "Failed to read packet")
        }

        ctx.fireChannelRead(wrapInboundOut(packet))
        return .continue
    }
}

/// Encoder/Decoder error
struct CodingError: Error {
    var message: String
}

public class PacketHandler: ChannelInboundHandler {
    public typealias InboundIn = Packet
    public typealias InboundOut = Packet
    public typealias OutboundIn = Packet
    public typealias OutbountOut = Packet
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        trace(self)

        let packet: Packet = unwrapInboundIn(data)

        // TODO kex decoder
        let kexHeaderLength = 17

        var buffer = ctx.channel.allocator.buffer(capacity: packet.payload.count)
        // TODO how inneficient is this if at all?
        buffer.write(bytes: packet.payload)
        buffer.moveReaderIndex(forwardBy: kexHeaderLength)

        let nameList = NameList(readFrom: &buffer)
        print(nameList ?? "<empty name list>")


//        let payload = packet.payload[(kexHeaderLength + nameListHeaderLength)...].withUnsafeBufferPointer {
//            String.decodeCString($0.baseAddress, as: UTF8.self, repairingInvalidCodeUnits: true)
//        }
//
//        print(nameList ?? "<empty payload>")
    }
}
