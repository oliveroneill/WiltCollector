import Foundation

public class WiltDatabase: DatabaseInterface {
    private let firestore: FireStoreInterface
    private let bigQuery: BigQueryInterface

    public init(projectID: String) throws {
        firestore = try FireStoreInterface(projectID: projectID)
        bigQuery = try BigQueryInterface(projectId: projectID)
    }

    public func getUsers() throws -> AnySequence<User> {
        return try firestore.getUsers()
    }

    public func getTimeOfLastUpdate(user: User) throws -> TimeInterval {
        return try bigQuery.getTimeOfLastUpdate(user: user)
    }

    public func insert(items: [PlayRecord], user: User) throws {
        try bigQuery.insert(items: items, user: user)
    }
}
