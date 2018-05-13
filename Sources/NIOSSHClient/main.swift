
import NIOSSH
import NIO

class SSHClientApplication {

    let client = SSHClient()
    
    func run () {
        print("\(type(of: self)).\(#function)")
        client.connect(host: "::1", port: 2020) { [unowned self] in
            print($0)
            switch $0 {
            case .connected: self.connected()
            case .error(let error): print(error)
            }
        }
    }
    
    func connected () {
        let line = readLine()!
        print("Closing because you entered \(line)")

        client.close {
            switch $0 {
            case .closed: print("Closed")
            case .error(let error): print(error)
            }
        }
    }
}

SSHClientApplication().run()
