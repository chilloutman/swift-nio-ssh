
import NIOSSH
import Foundation

class SSHClientApplication: SSHClientDelegate {

    let client = SSHClient(queue: DispatchQueue.main)

    init () {
        client.delegate = self
    }
    
    func run () {
        print("\(type(of: self)).\(#function)")
        client.connect(host: "::1", port: 2020)
    }

    func connected(client: SSHClient) {
        print("Connected!")

        let line = readLine()!
        print("Closing because you entered \(line)")

        client.close()
    }

    func closed(client: SSHClient) {
        print("Closed!")
        exit(0)
    }

    func error(client: SSHClient, error: Error) {
        print(error)
    }
    
}

let application = SSHClientApplication()
application.run()

_ = Unmanaged.passUnretained(application) // ARC, please don't release this

RunLoop.current.run()
