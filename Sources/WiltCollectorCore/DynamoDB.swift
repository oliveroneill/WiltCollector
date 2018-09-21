import Foundation
import SwiftAWSDynamodb
import AWSSDKSwiftCore

let userTable = "WiltUsers"
let historyTable = "WiltPlayHistory"

/// DynamoDB interface for getting users and updating play histories
public class DynamoDBInterface: DatabaseInterface {
    private let db = Dynamodb()
    public init() {}

    /// Get Wilt users
    ///
    /// - Returns: Users signed up to Wilt
    /// - Throws: If the data is not as expected
    public func getUsers() throws -> [User] {
        let result = try db.scan(Dynamodb.ScanInput(tableName: userTable))
        guard let items = result.items else {
            throw UserQueryError.unexpectedFailure
        }
        return try items.map {
            guard let id = $0["id"]?.s,
                let accessToken = $0["access_token"]?.s,
                let refreshAccessToken = $0["refresh_token"]?.s,
                let expiresAt = $0["expires_at"]?.n else {
                    throw UserQueryError.unexpectedFailure
            }
            guard let interval = Double(expiresAt) else {
                throw UserQueryError.unexpectedFailure
            }
            return User(
                id: id,
                accessToken: accessToken,
                refreshAccessToken: refreshAccessToken,
                expiresAt: Date(timeIntervalSinceReferenceDate: TimeInterval(interval))
            )
        }
    }

    /// Get the time of the last play for the specified user
    ///
    /// - Parameter user: The user to query
    /// - Returns: Time interval since 1970 of the last play of the user
    /// - Throws: If the database query fails
    public func getTimeOfLastUpdate(user: User) throws -> TimeInterval {
        let result = try db.query(
            Dynamodb.QueryInput(
                keyConditions: [
                    "user_id": Dynamodb.Condition(
                        comparisonOperator: .eq,
                        attributeValueList: [Dynamodb.AttributeValue(s: user.id)]
                    )
                ],
                tableName: historyTable,
                scanIndexForward: false,
                limit: 1
            )
        )
        guard let latest = result.items?.first else {
            throw LastUpdateError.noEntries
        }
        guard let date = latest["date"]?.n else {
            throw LastUpdateError.invalidRecord
        }
        guard let time = TimeInterval(date) else {
            throw LastUpdateError.invalidDate
        }
        return time
    }

    /// Insert record for user
    ///
    /// - Parameters:
    ///   - item: The track that was played
    ///   - user: The user that played the track
    /// - Throws: If the insert fails
    public func insert(item: PlayRecord, user: User) throws {
        let track = item.track
        let artists = track.artists.map { $0.name }
        let playedAt = "\(item.playedAt.timeIntervalSince1970)"
        _ = try db.putItem(
            Dynamodb.PutItemInput(
                item: [
                    "primary_artist": Dynamodb.AttributeValue(s: artists.first),
                    "artists": Dynamodb.AttributeValue(ss: artists),
                    "name": Dynamodb.AttributeValue(s: track.name),
                    "date": Dynamodb.AttributeValue(n: playedAt),
                    "track_id": Dynamodb.AttributeValue(s: track.id),
                    "user_id": Dynamodb.AttributeValue(s: user.id),
                    ],
                tableName: historyTable
            )
        )
    }
}
