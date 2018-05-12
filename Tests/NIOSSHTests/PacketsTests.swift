import XCTest

@testable import NIOSSH
import NIO

class PacketTest: XCTestCase {
    
    func testInit() {
        let packet = Packet(payload: [2, 2], padding: [3, 3, 3], mac: [4, 4, 4, 4])
        
        XCTAssertEqual(packet.packetLength, 6)
        XCTAssertEqual(packet.paddingLength, 3)
        XCTAssertEqual(packet.payload, [2, 2])
        XCTAssertEqual(packet.padding, [3, 3, 3])
        XCTAssertEqual(packet.mac, [4, 4, 4, 4])
    }

    func testReadWrite() {
        let packetOut = Packet(payload: [2, 2], padding: [3, 3, 3], mac: [4, 4, 4, 4])
        var buffer = ByteBufferAllocator().buffer(capacity: Int(packetOut.packetLength))
        packetOut.write(to: &buffer)
        
        let packetIn = Packet(readFrom: &buffer, macAlgorithm: .none)
        
        XCTAssertNotNil(packetIn)
        XCTAssertEqual(packetIn!, packetOut)
    }
    
}
