
import NIO

public class SSHClient {
    public init() {
        
    }

    private let group = MultiThreadedEventLoopGroup(numThreads: 1)
    private var channel: Channel?
    
    public func connect(host: String, port: Int, callback: @escaping (ConnectResult) -> ()) {
        let bootstrap = ClientBootstrap(group: group)
            .channelInitializer { channel in
                channel.pipeline.addHandlers(
                    ProtocolVersionExchangeHandler(),
                    PackedDecoder(),
                    PacketHandler(),
                    first: false)
            }

        do {
            channel = try bootstrap.connect(host: host, port: port).wait()
            callback(.connected)
        } catch {
            callback(.error(error))
        }

//        let futureChannel = bootstrap.connect(host: host, port: port)
//        futureChannel.whenSuccess { [unowned self] in
//            self.channel = $0
//            callback(.connected)
//        }
//        futureChannel.whenFailure { callback(.error($0)) }
    }

    public func close (callback: @escaping (CloseResult) -> ()) {
        group.shutdownGracefully {
            if let error = $0 {
                callback(.error(error))
            } else {
                callback(.closed)
            }
        }
    }
    
    public func wait () {
        try! channel?.closeFuture.wait()
    }

    public enum ConnectResult {
        case connected
        case error(Error)
    }

    public enum CloseResult {
        case closed
        case error(Error)
    }

}
