import XCTest
@testable import WiltCollectorCore

/// Define equality for list of tuples to make tests easier
func ==(lhs: [(PlayRecord, User)], rhs: [(PlayRecord, User)]) -> Bool {
    guard lhs.count == rhs.count else {
        return false
    }
    for i in 0..<lhs.count {
        guard lhs[i] == rhs[i] else {
            return false
        }
    }
    return true
}

final class WiltCollectorCoreTests: XCTestCase {
    class FakePlayHistory: PlayHistoryInterface {
        private let `return`: [PlayRecord]
        init(return: [PlayRecord]) {
            self.return = `return`
        }
        func getRecentlyPlayed(callback: @escaping ([PlayRecord]) -> Void) {
            callback(self.return)
        }
    }

    class FakeDatabase: DatabaseInterface {
        var lastUpdateCalls: [User] = []
        var insertCalls: [([PlayRecord], User)] = []
        private let timeOfLastUpdate: TimeInterval
        init(timeOfLastUpdate: TimeInterval) {
            self.timeOfLastUpdate = timeOfLastUpdate
        }

        func getUsers() throws -> AnySequence<User> {
            return AnySequence([])
        }

        func getTimeOfLastUpdate(user: User) throws -> TimeInterval {
            lastUpdateCalls.append(user)
            return timeOfLastUpdate
        }

        func insert(items: [PlayRecord], user: User) throws {
            insertCalls.append((items, user))
        }
    }

    // To make it easier to create play records
    private static func generateRecord(track: String, artist: String,
                                       id: String,
                                       date: Date = Date()) -> PlayRecord {
        return PlayRecord(
            track: Track(artists: [Artist(name: artist)], id: id, name: track),
            playedAt: date
        )
    }

    let user = User(
        id: "id-123x",
        accessToken: "token1",
        refreshAccessToken: "token2",
        expiresAt: Date()
    )
    let records = [
        generateRecord(track: "x", artist: "ART", id: "id-123"),
        generateRecord(track: "y", artist: "Test", id: "id-231"),
        generateRecord(track: "z", artist: "555", id: "id-676")
    ]

    func testUpdate() {
        let client = FakePlayHistory(return: records)
        let db = FakeDatabase(timeOfLastUpdate: TimeInterval(0))
        update(user: user, client: client, from: db) { [unowned self] in
            XCTAssertNil($0)
            XCTAssertEqual(1, db.lastUpdateCalls.count)
            XCTAssertEqual(self.user, db.lastUpdateCalls.first)
            XCTAssertEqual(1, db.insertCalls.count)
            XCTAssert((self.records, self.user) == db.insertCalls.first!)
        }
    }

    func testUpdateFiltersDates() {
        let firstAcceptableDate = records[0].playedAt
        // A record that is too far in the past
        let filtered = WiltCollectorCoreTests.generateRecord(
            track: "test", artist: "please", id: "idd",
            date: firstAcceptableDate.addingTimeInterval(-10000)
        )
        let client = FakePlayHistory(return: records + [filtered])
        let db = FakeDatabase(
            // Subtract 100 so that all dates in records are accepted
            timeOfLastUpdate: firstAcceptableDate.timeIntervalSince1970 - 100
        )
        update(user: user, client: client, from: db) { [unowned self] in
            XCTAssertNil($0)
            XCTAssertEqual(1, db.lastUpdateCalls.count)
            XCTAssertEqual(self.user, db.lastUpdateCalls.first)
            XCTAssertEqual(1, db.insertCalls.count)
            XCTAssert((self.records, self.user) == db.insertCalls.first!)
        }
    }

    /// Fake error
    enum TestError: Error {
        case err
    }

    func testUpdateHandlesFailedInserts() {
        class FakeDatabase: DatabaseInterface {
            var insertCalls: [([PlayRecord], User)] = []
            func getUsers() throws -> AnySequence<User> {
                return AnySequence([])
            }
            func getTimeOfLastUpdate(user: User) throws -> TimeInterval {
                return 0
            }
            func insert(items: [PlayRecord], user: User) throws {
                insertCalls.append((items, user))
                if insertCalls.count == 0 {
                    throw TestError.err
                }
            }
        }
        let client = FakePlayHistory(return: records)
        let db = FakeDatabase()
        update(user: user, client: client, from: db) { [unowned self] in
            XCTAssertNil($0)
            XCTAssertEqual(1, db.insertCalls.count)
            XCTAssert((self.records, self.user) == db.insertCalls.first!)
        }
    }

    func testUpdateHandlesNoLastUpdate() {
        class FakeDatabase: DatabaseInterface {
            var insertCalls: [([PlayRecord], User)] = []
            func getUsers() throws -> AnySequence<User> {
                return AnySequence([])
            }

            func getTimeOfLastUpdate(user: User) throws -> TimeInterval {
                throw TestError.err
            }

            func insert(items: [PlayRecord], user: User) throws {
                insertCalls.append((items, user))
            }
        }
        let client = FakePlayHistory(return: records)
        let db = FakeDatabase()
        update(user: user, client: client, from: db) { [unowned self] in
            XCTAssertNil($0)
            XCTAssertEqual(1, db.insertCalls.count)
            XCTAssert((self.records, self.user) == db.insertCalls.first!)
        }
    }

    func testDateResultDecode() throws {
        let data = """
        {
            "date": "1.535071435223E9"
        }
        """.data(using: .utf8)!
        let result = try JSONDecoder().decode(DateResult.self, from: data)
        XCTAssertEqual(1535071435.223, result.date)
    }
}
