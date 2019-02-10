import Foundation

/// Model for an Artist
public struct Artist: Equatable {
    public let name: String
}

/// Model for a track
public struct Track: Equatable {
    public let artists: [Artist]
    public let id: String
    public let name: String
}

/// Model for a track played at a specific time
public struct PlayRecord: Equatable {
    public let track: Track
    public let playedAt: Date
}

/// Interface for querying a user's recently played songs
public protocol PlayHistoryInterface {
    func getRecentlyPlayed(callback: @escaping ([PlayRecord]) -> Void)
}

/// Interface doing database operations
public protocol DatabaseInterface {
    func getUsers() throws -> AnySequence<User>
    func getTimeOfLastUpdate(user: User) throws -> TimeInterval
    func insert(items: [PlayRecord], user: User) throws
}

/// A user
public struct User: Decodable, Equatable {
    let id: String
    // These tokens are Spotify specific
    let accessToken: String
    let refreshAccessToken: String
    let expiresAt: Date
    init(id: String, accessToken: String, refreshAccessToken: String,
         expiresAt: Date) {
        self.id = id
        self.accessToken = accessToken
        self.refreshAccessToken = refreshAccessToken
        self.expiresAt = expiresAt
    }
}

/// Errors that occur when getting all users
///
/// - unexpectedFailure: Something went wrong with the query
public enum UserQueryError: Error {
    case unexpectedFailure
}

/// Errors that occur when getting the time of last update
///
/// - noEntries: There were no entries
/// - invalidRecord: The last entry was invalid
/// - invalidDate: The last entry did not have a valid date
public enum LastUpdateError: Error {
    case noEntries
    case invalidRecord
    case invalidDate
}

/// Update a user's database with new play history records
///
/// - Parameters:
///   - user: The user to update
///   - client: The client to query play history on
///   - dao: The database to insert to
///   - completionHandler: Called upon completion
public func update(user: User, client: PlayHistoryInterface,
                   from dao: DatabaseInterface,
                   completionHandler: @escaping ((Error?) -> Void)) {
    let lastUpdate = (try? dao.getTimeOfLastUpdate(user: user)) ?? 0
    client.getRecentlyPlayed {
        let filtered = $0.filter { $0.playedAt.timeIntervalSince1970 > lastUpdate }
        do {
            try dao.insert(items: filtered, user: user)
            completionHandler(nil)
        } catch {
            print("Failed to insert because of \(error)")
            completionHandler(error)
        }
    }
}
