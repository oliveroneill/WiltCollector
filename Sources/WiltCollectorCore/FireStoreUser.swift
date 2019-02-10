import Foundation

/// The FireStore format for a User
struct FireStoreUser: Decodable {
    let access_token: FireStoreValue
    let refresh_token: FireStoreValue
    let expires_at: FireStoreValue
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

/// A sequence of users that makes calls based on pagination
struct FireStoreUserSequence: Sequence, IteratorProtocol {
    private let client: UserDatabaseClient
    private var token: String?
    private var users: [User] = []
    private var count: Int = 0
    // Used to ensure that we don't ignore nil page tokens that signify the
    // last page
    private var firstCall = true

    init(client: UserDatabaseClient) {
        self.client = client
    }

    mutating func next() -> User? {
        // If we've reached the end of the page then we should request another
        guard count < users.count else {
            // Ensure that we stop once we've received a nil page token
            guard firstCall || token != nil else {
                return nil
            }
            do {
                try updatePage()
            } catch {
                return nil
            }
            return next()
        }
        firstCall = false
        defer { count += 1 }
        // Run through users
        return users[count]
    }

    /// Request next page and update state
    ///
    /// - Throws: If request fails
    mutating func updatePage() throws {
        let (users, token) = try getUsers()
        self.token = token
        self.users = users
        self.count = 0
    }

    /// Get wilt users. Will block while making call to Firestore
    ///
    /// - Returns: A list of users
    /// - Throws: If an error occurs.
    func getUsers() throws -> (users: [User], token: String?) {
        let s = DispatchSemaphore(value: 0)
        var response: ListResponse<FireStoreUser>?
        client.list(pageToken: token) { (result: ListResponse<FireStoreUser>) in
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
        return try (users.documents.map(toUser), users.nextPageToken)
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
