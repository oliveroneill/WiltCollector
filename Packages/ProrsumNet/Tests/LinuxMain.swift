import XCTest
@testable import ProrsumNetTests

XCTMain([
    testCase(TCPTests.allTests),
    testCase(UDPTests.allTests),
    testCase(SocketTests.allTests)
])
