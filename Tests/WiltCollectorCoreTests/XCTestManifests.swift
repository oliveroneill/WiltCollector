import XCTest

extension FireStoreClientTests {
    static let __allTests = [
        ("testList", testList),
        ("testListError", testListError),
        ("testListWithInvalidJSON", testListWithInvalidJSON),
    ]
}

extension FireStoreInterfaceTests {
    static let __allTests = [
        ("testGetUsers", testGetUsers),
        ("testGetUsersError", testGetUsersError),
        ("testGetUsersInvalidDate", testGetUsersInvalidDate),
        ("testGetUsersInvalidType", testGetUsersInvalidType),
        ("testGetUsersMultiplePages", testGetUsersMultiplePages),
    ]
}

extension WiltCollectorCoreTests {
    static let __allTests = [
        ("testDateResultDecode", testDateResultDecode),
        ("testUpdate", testUpdate),
        ("testUpdateFiltersDates", testUpdateFiltersDates),
        ("testUpdateHandlesFailedInserts", testUpdateHandlesFailedInserts),
        ("testUpdateHandlesNoLastUpdate", testUpdateHandlesNoLastUpdate),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(FireStoreClientTests.__allTests),
        testCase(FireStoreInterfaceTests.__allTests),
        testCase(WiltCollectorCoreTests.__allTests),
    ]
}
#endif
