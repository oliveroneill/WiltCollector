import Foundation
import BigQuerySwift

/// An interface for retrieving a list of users from a database.
/// This is purely for testing purposes and is pretty tightly coupled to
/// Firestore :(
protocol UserDatabaseClient {
    /// List firestore users
    ///
    /// - Parameter completionHandler: Called when the call is complete
    func list(completionHandler: @escaping (ListResponse<FireStoreUser>) -> Void)

    /// List firestore users
    ///
    /// - Parameters:
    ///   - pageToken: Token for the page of users to list
    ///   - completionHandler: Called when the call is complete
    func list(pageToken: String?, completionHandler: @escaping (ListResponse<FireStoreUser>) -> Void)
}

extension FireStoreClient: UserDatabaseClient {
    func list(completionHandler: @escaping (ListResponse<FireStoreUser>) -> Void) {
        list(pageToken: nil, completionHandler: completionHandler)
    }
}

/// Interface for retrieving wilt users by Firestore instance
class FireStoreInterface {
    private let client: UserDatabaseClient

    /// Create FireStoreClient.
    ///
    /// - Parameter client: Specify custom client
    init(client: UserDatabaseClient) {
        self.client = client
    }

    /// Create FireStoreClient. Will block while retrieving auth token
    ///
    /// - Parameter projectID: The firebase project ID
    /// - Throws: If auth fails
    init(projectID: String) throws {
        // Run through auth flow to retrieve token
        let provider = FireStoreAuthProvider()
        let s = DispatchSemaphore(value: 0)
        var result: AuthResponse?
        try provider.getAuthenticationToken {
            result = $0
            s.signal()
        }
        s.wait()
        guard let r = result else {
            fatalError("Unexpected empty auth response")
        }
        if case let .error(e) = r {
            throw e
        }
        guard case let .token(t) = r else {
            fatalError("No error and no token?")
        }
        // Create client
        client = FireStoreClient(
            authenticationToken: t,
            projectID: projectID,
            collectionID: "users"
        )
    }

    func getUsers() throws -> AnySequence<User> {
        return AnySequence(FireStoreUserSequence(client: client))
    }
}
