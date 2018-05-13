
import XCTest

@testable import NIOSSH
import NIO

private let allocator = ByteBufferAllocator()

class PacketTest: XCTestCase {
    
    func testInit() {
        let packet = Packet(payload: [2, 2], padding: [3, 3, 3], mac: [4, 4, 4, 4])
        
        XCTAssertEqual(packet.packetLength, 6)
        XCTAssertEqual(packet.paddingLength, 3)
        XCTAssertEqual(packet.payload, [2, 2])
        XCTAssertEqual(packet.padding, [3, 3, 3])
        XCTAssertEqual(packet.mac, [4, 4, 4, 4])
    }

    func testBuffer() throws {
        let packetOut = Packet(payload: [2, 2], padding: [3, 3, 3], mac: [])
        var buffer = allocator.buffer(capacity: Int(packetOut.packetLength))
        packetOut.write(to: &buffer)

        let packetIn = try requireNotNil(Packet(readFrom: &buffer), name: "packetIn")

        XCTAssertEqual(packetIn, packetOut)
    }

    func testBufferWithHeaderAndMAC() throws {
        let packetOut = Packet(payload: [2, 2], padding: [3, 3, 3], mac: [4, 4, 4, 4])
        var buffer = allocator.buffer(capacity: Int(packetOut.packetLength))
        packetOut.write(to: &buffer)

        let header = try requireNotNil(PacketHeader(readFrom: &buffer), name: "header")
        let packetIn = try requireNotNil(Packet(header: header, readFrom: &buffer, macAlgorithm: .none), name: "packetIn")
        XCTAssertEqual(packetIn, packetOut)
    }

}

class NameListTest: XCTestCase {

    func testEmptyToBuffer() {
        let nameList = NameList(names: [])

        XCTAssertEqual(nameList.length, 0)
    }

    func testEmptyFromBuffer() throws {
        var buffer = allocator.buffer(capacity: MemoryLayout<UInt32>.size)
        buffer.write(integer: UInt32(0))
        let nameList = try requireNotNil(NameList(readFrom: &buffer), name: "nameList")

        nameList.write(to: &buffer)
        let bytes = try requireNotNil(buffer.readBytes(length: buffer.readableBytes), name: "bytes")

        XCTAssertEqual(bytes, [0, 0, 0, 0])
    }

    func testEmptyFromBytes() throws {
        let nameList: NameList = try requireNotNil(NameList(bytes: [0, 0, 0, 0]), name: "nameList")

        let emptyNameList = NameList(names: [])
        XCTAssertEqual(nameList, emptyNameList)
    }

    func testFromBytes() throws {
        let nameList: NameList = try requireNotNil(NameList(bytes: [0, 0, 0, 4, 0x7a, 0x6c, 0x69, 0x62]), name: "nameList")

        let emptyNameList = NameList(names: ["zlib"])
        XCTAssertEqual(nameList, emptyNameList)
    }
}
