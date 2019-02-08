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
            completionHandler(response)
        }
    }

    func testGetUsers() {
        let expected = [
            User(
                id: "a_user_id",
                accessToken: "anaccesstoken",
                refreshAccessToken: "arefreshtoken",
                expiresAt: Date(timeIntervalSince1970: 1548671336.365
                )
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
            XCTAssertEqual(users, expected)
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
                error as! FireStoreInterface.InvalidUserError,
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
                error as! FireStoreInterface.InvalidUserError,
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
}
