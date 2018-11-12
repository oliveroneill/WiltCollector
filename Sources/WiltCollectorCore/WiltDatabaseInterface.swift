import Foundation

public class WiltDatabase: DatabaseInterface {
    private let dynamo = DynamoDBInterface()
    private let bigQuery: BigQueryInterface

    public init(bigQueryProjectId: String) throws {
        bigQuery = try BigQueryInterface(projectId: bigQueryProjectId)
    }

    public func getUsers() throws -> [User] {
        return try dynamo.getUsers()
    }

    public func getTimeOfLastUpdate(user: User) throws -> TimeInterval {
        return try bigQuery.getTimeOfLastUpdate(user: user)
    }

    public func insert(items: [PlayRecord], user: User) throws {
        try bigQuery.insert(items: items, user: user)
    }
}
