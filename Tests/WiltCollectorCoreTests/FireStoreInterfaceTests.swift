import XCTest
@testable import WiltCollectorCore

final class FireStoreInterfaceTests: XCTestCase {
    private enum TestError: Error {
        case test
    }

    class FakeClient : UserDatabaseClient {
        private let response: ListResponse<FireStoreUser>
        init(response: ListResponse<FireStoreUser>) {
            self.response = response
        }
        func list(completionHandler: @escaping (ListResponse<FireStoreUser>) -> Void) {
            list(pageToken: nil, completionHandler: completionHandler)
        }
        func list(pageToken: String?, completionHandler: @escaping (ListResponse<FireStoreUser>) -> Void) {
            completionHandler(response)
        }
    }

    func testGetUsers() {
        let expected = [
            User(
                id: "a_user_id",
                accessToken: "anaccesstoken",
                refreshAccessToken: "arefreshtoken",
                expiresAt: Date(timeIntervalSince1970: 1548671336.365)
            )
        ]
        let response = ListResponse<FireStoreUser>.response(
            ListHTTPResponse(
                documents: [
                    ListDocument(
                        name: "projects/dbid-123/databases/(default)/documents/users/a_user_id",
                        fields: FireStoreUser(
                            access_token: .stringValue("anaccesstoken"),
                            refresh_token: .stringValue("arefreshtoken"),
                            expires_at: .timestampValue("2019-01-28T10:28:56.365Z")
                        )
                    )
                ],
                nextPageToken: nil
            )
        )
        let client = FireStoreInterface(client: FakeClient(response: response))
        do {
            let users = try client.getUsers()
            XCTAssertEqual(Array(users), expected)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGetUsersInvalidType() {
        let response = ListResponse<FireStoreUser>.response(
            ListHTTPResponse(
                documents: [
                    ListDocument(
                        name: "projects/dbid-123/databases/(default)/documents/users/a_user_id",
                        fields: FireStoreUser(
                            access_token: .integerValue(123),
                            refresh_token: .stringValue("arefreshtoken"),
                            expires_at: .timestampValue("2019-01-28T10:28:56.365Z")
                        )
                    )
                ],
                nextPageToken: nil
            )
        )
        let client = FireStoreInterface(client: FakeClient(response: response))
        do {
            _ = try client.getUsers()
        } catch {
            XCTAssertEqual(
                error as! InvalidUserError,
                .unexpectedType("access token")
            )
        }
    }

    func testGetUsersInvalidDate() {
        let response = ListResponse<FireStoreUser>.response(
            ListHTTPResponse(
                documents: [
                    ListDocument(
                        name: "projects/dbid-123/databases/(default)/documents/users/a_user_id",
                        fields: FireStoreUser(
                            access_token: .stringValue("anaccesstoken"),
                            refresh_token: .stringValue("arefreshtoken"),
                            expires_at: .timestampValue("1st of November 2020")
                        )
                    )
                ],
                nextPageToken: nil
            )
        )
        let client = FireStoreInterface(client: FakeClient(response: response))
        do {
            _ = try client.getUsers()
        } catch {
            XCTAssertEqual(
                error as! InvalidUserError,
                .invalidDateFormat("1st of November 2020")
            )
        }
    }

    func testGetUsersError() {
        let response = ListResponse<FireStoreUser>.error(TestError.test)
        let client = FireStoreInterface(client: FakeClient(response: response))
        do {
            _ = try client.getUsers()
        } catch {
            XCTAssertNotNil(error as? TestError)
        }
    }

    // Client that accepts multiple response and monitors page tokens
    class FakeMultiPageClient : UserDatabaseClient {
        private let responses: [ListResponse<FireStoreUser>]
        private var count = 0
        private(set) var tokensCalled: [String?] = []
        init(responses: [ListResponse<FireStoreUser>]) {
            self.responses = responses
        }
        func list(completionHandler: @escaping (ListResponse<FireStoreUser>) -> Void) {
            list(pageToken: nil, completionHandler: completionHandler)
        }
        func list(pageToken: String?, completionHandler: @escaping (ListResponse<FireStoreUser>) -> Void) {
            defer { count += 1 }
            tokensCalled.append(pageToken)
            completionHandler(responses[count])
        }
    }

    func testGetUsersMultiplePages() {
        let expectedToken = "a_random_page_token123"
        // The expected users
        let expected = [
            User(
                id: "a_user_id",
                accessToken: "anaccesstoken",
                refreshAccessToken: "arefreshtoken",
                expiresAt: Date(timeIntervalSince1970: 1548671336.365)
            ),
            User(
                id: "userid2",
                accessToken: "ac1",
                refreshAccessToken: "arf2",
                expiresAt: Date(timeIntervalSince1970: 1548671337.365)
            ),
            User(
                id: "anotherid",
                accessToken: "45678",
                refreshAccessToken: "token33",
                expiresAt: Date(timeIntervalSince1970: 1548671936.365)
            )
        ]
        // Two pages
        let responses = [
            ListResponse<FireStoreUser>.response(
                ListHTTPResponse(
                    // The first page contains two users
                    documents: [
                        ListDocument(
                            name: "projects/dbid-123/databases/(default)/documents/users/a_user_id",
                            fields: FireStoreUser(
                                access_token: .stringValue("anaccesstoken"),
                                refresh_token: .stringValue("arefreshtoken"),
                                expires_at: .timestampValue("2019-01-28T10:28:56.365Z")
                            )
                        ),
                        ListDocument(
                            name: "projects/dbid-123/databases/(default)/documents/users/userid2",
                            fields: FireStoreUser(
                                access_token: .stringValue("ac1"),
                                refresh_token: .stringValue("arf2"),
                                expires_at: .timestampValue("2019-01-28T10:28:57.365Z")
                            )
                        )
                    ],
                    nextPageToken: expectedToken
                )
            ),
            ListResponse<FireStoreUser>.response(
                ListHTTPResponse(
                    documents: [
                        ListDocument(
                            name: "projects/dbid-123/databases/(default)/documents/users/anotherid",
                            fields: FireStoreUser(
                                access_token: .stringValue("45678"),
                                refresh_token: .stringValue("token33"),
                                expires_at: .timestampValue("2019-01-28T10:38:56.365Z")
                            )
                        )
                    ],
                    nextPageToken: nil
                )
            )
        ]
        let fakeClient = FakeMultiPageClient(responses: responses)
        let client = FireStoreInterface(client: fakeClient)
        do {
            let users = try client.getUsers()
            XCTAssertEqual(Array(users), expected)
            // Ensure it's called with the token on second request
            XCTAssertEqual([nil, expectedToken], fakeClient.tokensCalled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
