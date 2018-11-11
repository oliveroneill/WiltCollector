import Foundation
import SwiftAWSDynamodb
import AWSSDKSwiftCore

let userTable = "WiltUsers"

/// DynamoDB interface for getting users and updating play histories
public class DynamoDBInterface {
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
}
