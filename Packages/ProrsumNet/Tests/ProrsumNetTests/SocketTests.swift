//
//  SocketTests.swift
//  ProrsumNetPackageDescription
//
//  Created by Yuki Takei on 2017/11/08.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif
import XCTest
import Foundation
import Dispatch
@testable import ProrsumNet

class SocketTests: XCTestCase {
    
    func createSocket(addressFamily: AddressFamily, sockType: SockType, protocolType: ProtocolType, completion: (Socket) throws -> Void) {
        do {
            let socket = try Socket(addressFamily: addressFamily, sockType: sockType, protocolType: protocolType)
            try completion(socket)
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testCreate() {
        createSocket(addressFamily: .inet, sockType: .stream, protocolType: .tcp) { socket in
            XCTAssertEqual(socket.addressFamily, AddressFamily.inet)
            XCTAssertEqual(socket.sockType, SockType.stream)
            XCTAssertEqual(socket.protocolType, ProtocolType.tcp)
        }
        
        createSocket(addressFamily: .inet6, sockType: .stream, protocolType: .tcp) { socket in
            XCTAssertEqual(socket.addressFamily, AddressFamily.inet6)
            XCTAssertEqual(socket.sockType, SockType.stream)
            XCTAssertEqual(socket.protocolType, ProtocolType.tcp)
        }
        
        createSocket(addressFamily: .inet6, sockType: .dgram, protocolType: .udp) { socket in
            XCTAssertEqual(socket.addressFamily, AddressFamily.inet6)
            XCTAssertEqual(socket.sockType, SockType.dgram)
            XCTAssertEqual(socket.protocolType, ProtocolType.udp)
        }
    }
    
    func testSetBlocking() {
        createSocket(addressFamily: .inet, sockType: .stream, protocolType: .tcp) { socket in
            XCTAssertTrue(socket.isBlocking, "default mode is blocking")
            try socket.setBlocking(shouldBlock: false)
            XCTAssertFalse(socket.isBlocking, "socket is non-blocking mode")
            try socket.setBlocking(shouldBlock: true)
            XCTAssertTrue(socket.isBlocking, "socket is blocking mode")
        }
    }
    
    static var allTests : [(String, (SocketTests) -> () throws -> Void)] {
        return [
            ("testCreate", testCreate),
            ("testSetBlocking", testSetBlocking)
        ]
    }
}
