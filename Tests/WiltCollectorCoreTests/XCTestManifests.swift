import XCTest

extension WiltCollectorCoreTests {
    static let __allTests = [
        ("testUpdate", testUpdate),
        ("testUpdateFiltersDates", testUpdateFiltersDates),
        ("testUpdateHandlesFailedInserts", testUpdateHandlesFailedInserts),
        ("testUpdateHandlesNoLastUpdate", testUpdateHandlesNoLastUpdate),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(WiltCollectorCoreTests.__allTests),
    ]
}
#endif
