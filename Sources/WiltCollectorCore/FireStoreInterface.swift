import Foundation
import BigQuerySwift

/// The FireStore format for a User
struct FireStoreUser: Decodable {
    let access_token: FireStoreValue
    let refresh_token: FireStoreValue
    let expires_at: FireStoreValue
}

/// An interface for retrieving a list of users from a database.
/// This is purely for testing purposes and is pretty tightly coupled to
/// Firestore :(
protocol UserDatabaseClient {
    /// List firestore users
    ///
    /// - Parameter completionHandler: Called when the call is complete
    func list(completionHandler: @escaping (ListResponse<FireStoreUser>) -> Void)
}

extension FireStoreClient: UserDatabaseClient {}

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

    /// Get wilt users. Will block while making call to Firestore
    ///
    /// - Returns: A list of users
    /// - Throws: If an error occurs.
    func getUsers() throws -> [User] {
        let s = DispatchSemaphore(value: 0)
        var response: ListResponse<FireStoreUser>?
        client.list { (result: ListResponse<FireStoreUser>) in
            response = result
            s.signal()
        }
        s.wait()
        if case let .error(e)? = response {
            throw e
        }
        guard case let .response(users)? = response else {
            fatalError("No error and no response?")
        }
        return try users.documents.map(toUser)
    }

    /// Error cases when parsing Firestore response
    ///
    /// - unexpectedType: The type does not match
    /// - unexpectedName: The name does not follow the correct format
    /// - invalidDateFormat: The date did not follow the correct format
    enum InvalidUserError: Error, Equatable {
        case unexpectedType(String)
        case unexpectedName(String)
        case invalidDateFormat(String)
    }

    /// Convert FireStoreUser to a more convenient User struct
    ///
    /// - Parameter user: a firestore user response
    /// - Returns: A User value
    /// - Throws: If parsing fails
    private func toUser(user: ListDocument<FireStoreUser>) throws -> User {
        let fields = user.fields
        guard let id = user.name.split(separator: "/").last else {
            throw InvalidUserError.unexpectedName(user.name)
        }
        guard case let .stringValue(accessToken) = fields.access_token else {
            throw InvalidUserError.unexpectedType("access token")
        }
        guard case let .stringValue(refreshToken) = fields.refresh_token else {
            throw InvalidUserError.unexpectedType("refresh token")
        }
        guard case let .timestampValue(expiresAt) = fields.expires_at else {
            throw InvalidUserError.unexpectedType("expires at")
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = dateFormatter.date(from: expiresAt) else {
            throw InvalidUserError.invalidDateFormat(expiresAt)
        }
        return User(
            id: String(id),
            accessToken: accessToken,
            refreshAccessToken: refreshToken,
            expiresAt: date
        )
    }
}
