
import NIO
import class Dispatch.DispatchQueue

public protocol SSHClientDelegate: class {
    func connected(client: SSHClient)
    func closed(client: SSHClient)
    func error(client: SSHClient, error: Error)
}

public class SSHClient {

    public weak var delegate: SSHClientDelegate?
    private let queue: DispatchQueue

    private let group: EventLoopGroup
    private let bootstrap: ClientBootstrap

    private var state: State = State.idle {
        didSet {
            print("SSHClient.state = \(state)")
            queue.async { [weak self] in
                guard let client = self, let delegate = client.delegate else { return }
                switch client.state {
                case .connected(_):
                    delegate.connected(client: client)
                case .idle:
                    delegate.closed(client: client)
                }
            }
        }
    }

    private enum State {
        case idle
        case connected(Channel)
    }

    public init(queue: DispatchQueue = DispatchQueue.main) {
        group = MultiThreadedEventLoopGroup(numThreads: 1)
        bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer(initializeChannel)
        self.queue = queue
    }

    public func connect(host: String, port: Int) {
        guard case .idle = state else { preconditionFailure() }

        let channelFuture = bootstrap.connect(host: host, port: port)

        channelFuture.whenSuccess { channel in
            channel.closeFuture.whenComplete { self.state = .idle }
            self.state = .connected(channel)
        }
        channelFuture.whenFailure(handleError)
    }

    public func close () {
        if case .connected(let channel) = state {
            channel.close(mode: .all, promise: nil)
        }
    }

    func handleError(_ error: Error) {
        queue.sync {
            delegate?.error(client: self, error: error)
            self.close()
        }
    }

    deinit {
        try! group.syncShutdownGracefully()
    }

}

private func initializeChannel(_ channel: Channel) -> EventLoopFuture<Void> {
    return channel.pipeline.addHandlers(
        ProtocolVersionExchangeHandler(),
        PackedDecoder(),
        PacketHandler(),
        first: false)
}
