// Disable print buffering for better AWS Lambda debugging
#if os(Linux)
import Glibc
#else
import Darwin
#endif
setbuf(stdout, nil)
setbuf(stderr, nil)

import Foundation
import WiltCollectorCore

func main() {
    guard let projectId = ProcessInfo.processInfo.environment["BIGQUERY_PROJECT_ID"] else {
        fatalError("Project ID not set")
    }
    let db: WiltDatabase
    do {
        db = try WiltDatabase(bigQueryProjectId: projectId)
    } catch {
        fatalError("Failed to create database: \(error)")
    }
    let users: [User]
    do {
        users = try db.getUsers()
    } catch {
        fatalError("Getting users failed: \(error)")
    }

    guard let clientID = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_ID"] else {
        fatalError("Client ID not set")
    }
    guard let clientSecret = ProcessInfo.processInfo.environment["SPOTIFY_CLIENT_SECRET"] else {
        fatalError("Client Secret not set")
    }

    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()

    /// Loop through users recursively and update their play history
    ///
    /// - Parameter index: The current index
    func updateUsersRecursively(index: Int) {
        // Check if we've finished all users
        if index >= users.count {
            print("Finished updating users")
            dispatchGroup.leave()
            return
        }
        let user = users[index]
        print("Creating client with", clientID)
        // Create client for this user
        let client = SpotifyPlayHistoryClient(
            user: user,
            clientID: clientID,
            clientSecret: clientSecret
        )
        print("Updating user:", user)
        update(user: user, client: client, from: db) {
            if let e = $0 {
                // Don't stop when errors occur
                print("Updating user failed", e)
            }
            // Continue through users
            updateUsersRecursively(index: index + 1)
        }
    }
    // Start at zero
    updateUsersRecursively(index: 0)
    dispatchGroup.notify(queue: DispatchQueue.main) {
        exit(EXIT_SUCCESS)
    }
    dispatchMain()
}

main()
