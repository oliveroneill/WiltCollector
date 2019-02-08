import XCTest
@testable import WiltCollectorCore

extension ListHTTPResponse: Equatable where T: Equatable {
    public static func == (lhs: ListHTTPResponse<T>, rhs: ListHTTPResponse<T>) -> Bool {
        return lhs.nextPageToken == rhs.nextPageToken &&
            lhs.documents == rhs.documents
    }
}

extension ListDocument: Equatable where T: Equatable {
    public static func == (lhs: ListDocument<T>, rhs: ListDocument<T>) -> Bool {
        return lhs.name == rhs.name && lhs.fields == rhs.fields
    }
}

final class FireStoreClientTests: XCTestCase {
    private struct TestRow: Decodable, Equatable {
        let string_test: FireStoreValue
        let test_date: FireStoreValue
        let another_string: FireStoreValue
    }

    private let authenticationToken = "TEST_TOKEN_123"
    private let projectID = "id-1234"
    private let collectionID = "dataset_name"

    private class MockClient: HTTPClient {
        private let response: (Data?, HTTPURLResponse?, Error?)
        var calls: [(url: String, headers: [String : String])] = []
        init(response: (Data?, HTTPURLResponse?, Error?)) {
            self.response = response
        }

        func get(url: String, headers: [String : String],
                 completionHandler: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
            calls.append((url: url, headers: headers))
            completionHandler(response.0, response.1, response.2)
        }
    }

    private enum TestError: Error {
        case test
    }

    func testList() {
        let data = """
        {
          "documents": [
            {
              "name": "projects/dbid-123/databases/(default)/documents/users/a_user_id",
              "fields": {
                "string_test": {
                  "stringValue": "here's a string thing yeah"
                },
                "test_date": {
                  "timestampValue": "2019-01-28T10:28:56.365Z"
                },
                "another_string": {
                  "stringValue": "useful string?"
                }
              },
              "createTime": "2019-01-28T01:01:21.286948Z",
              "updateTime": "2019-01-28T09:29:05.266134Z"
            }
          ]
        }
        """.data(using: .utf8)
        let expected = ListHTTPResponse(
            documents: [
                ListDocument(
                    name: "projects/dbid-123/databases/(default)/documents/users/a_user_id",
                    fields: TestRow(
                        string_test: .stringValue("here's a string thing yeah"),
                        test_date: .timestampValue("2019-01-28T10:28:56.365Z"),
                        another_string: .stringValue("useful string?")
                    )
                )
            ],
            nextPageToken: nil
        )
        let client = FireStoreClient(
            authenticationToken: authenticationToken,
            projectID: projectID,
            collectionID: collectionID,
            client: MockClient(response: (data, nil, nil))
        )
        client.list() { (response: ListResponse<TestRow>) in
            guard case let .response(r) = response else {
                XCTFail("Unexpected error \(response)")
                return
            }
            XCTAssertEqual(expected, r)
        }
    }

    func testListWithInvalidJSON() {
        let data = """
        {
          "random": "testing"
        }
        """.data(using: .utf8)
        let client = FireStoreClient(
            authenticationToken: authenticationToken,
            projectID: projectID,
            collectionID: collectionID,
            client: MockClient(response: (data, nil, nil))
        )
        client.list() { (response: ListResponse<TestRow>) in
            guard case let .error(e) = response else {
                XCTFail("Unexpected success")
                return
            }
            guard case .keyNotFound(_)? = e as? DecodingError else {
                XCTFail("Unexpected error \(e)")
                return
            }
        }
    }

    func testListError() {
        let expected = TestError.test
        let client = FireStoreClient(
            authenticationToken: authenticationToken,
            projectID: projectID,
            collectionID: collectionID,
            client: MockClient(response: (nil, nil, expected))
        )
        client.list() { (response: ListResponse<TestRow>) in
            guard case let .error(e) = response else {
                XCTFail("Unexpected error")
                return
            }
            XCTAssertEqual(expected, e as! FireStoreClientTests.TestError)
        }
    }
}
