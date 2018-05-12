
import NIO

public struct SSHClient {
    public init() {
        
    }
    
    public func connect(host: String, port: Int) {
        let group = MultiThreadedEventLoopGroup(numThreads: 1)
        let bootstrap = ClientBootstrap(group: group)
            .channelInitializer { channel in
                channel.pipeline.add(handler: SSHHandler())
        }
        defer {
            try! group.syncShutdownGracefully()
        }
        
        let channel = try? bootstrap.connect(host: host, port: port).wait()
        
        try! channel?.closeFuture.wait()
    }
}

//public class PackedDecoder: ChannelInboundHandler {
//    public typealias InboundIn = ByteBuffer
//
//    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
//        var buffer = unwrapInboundIn(data)
//        let packet = Packet(readFrom: &buffer, macAlgorithm: .none)
//        print(packet ?? "<nil>")
//    }
//}

public class SSHHandler: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
    
    private var state = ConnectionSetupState.versionExchange
    private var packetHeader: PacketHeader?
    private var packetBuffer: ByteBuffer?
    private var macAlgorithm = MACAlgorithm.none
    
    public init() {
        
    }
    
    public func channelActive(ctx: ChannelHandlerContext) {
        print("Connected")
        
        var buffer = ctx.channel.allocator.buffer(capacity: identificationString.utf8.count)
        buffer.write(string: identificationString)
        ctx.writeAndFlush(wrapOutboundOut(buffer), promise: nil)
    }
    
    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        print("# channelRead")
        
        switch state {
        case .versionExchange:
            let string = buffer.readString(length: buffer.readableBytes)
            print(string ?? "<nil>")
            state = .keyExchange
        case .keyExchange:
            if packetHeader == nil {
                if let header = PacketHeader(readFrom: &buffer) {
                    packetHeader = header
                    packetBuffer = ctx.channel.allocator.buffer(capacity: header.bodyLength(macAlgorithm: macAlgorithm))
                    writeToPacketBuffer(from: &buffer, header: header)
                    print(header)
                } else {
                    print("Failed to parse packet header")
                }
            } else if let header = packetHeader, var packetBuffer = packetBuffer {
                packetBuffer.write(buffer: &buffer)

                if packetBuffer.readableBytes >= header.bodyLength(macAlgorithm: macAlgorithm) {
                    let packet = Packet(header: header, readFrom: &packetBuffer, macAlgorithm: macAlgorithm)
                    print(packet ?? "<nil>")
                }
            }
        }
        
        ctx.fireChannelRead(data)
    }
    
    func writeToPacketBuffer (from: inout ByteBuffer, header: PacketHeader) {
        packetBuffer!.write(buffer: &from)
    }
    
    public func channelReadComplete(ctx: ChannelHandlerContext) {
        print("# channelReadComplete")
        
        ctx.fireChannelReadComplete()
    }
    
    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print(error)
        ctx.close(promise: nil)
    }
}

private enum ConnectionSetupState {
    case versionExchange
    case keyExchange
    
}

