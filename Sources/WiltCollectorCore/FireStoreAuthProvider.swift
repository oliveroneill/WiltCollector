import Foundation

import OAuth2
import BigQuerySwift

/// Handles authenticating a service account
struct FireStoreAuthProvider {
    /// Set scope to be Firestore
    private let scopes = [
        "https://www.googleapis.com/auth/datastore",
        "https://www.googleapis.com/auth/cloud-platform",
    ]

    init() {}

    /// Get an authentication token to be used in API calls.
    /// The credentials file is expected to be in the same directory as the
    /// running binary (ie. $pwd/credentials.json)
    ///
    /// - Parameter completionHandler: Called upon completion
    /// - Throws: If JWT creation fails
    func getAuthenticationToken(completionHandler: @escaping (AuthResponse) -> Void) throws {
        // Get current directory
        let currentDirectoryURL = URL(
            fileURLWithPath: FileManager.default.currentDirectoryPath
        )
        // Get URL of credentials file
        let credentialsURL = currentDirectoryURL.appendingPathComponent("credentials.json")
        guard let tokenProvider = ServiceAccountTokenProvider(
            credentialsURL: credentialsURL,
            scopes:scopes
        ) else {
            fatalError("Failed to create token provider")
        }
        // Request token
        try tokenProvider.withToken { (token, error) in
            if let token = token {
                completionHandler(.token(token.AccessToken!))
            } else {
                completionHandler(.error(error!))
            }
        }
    }
}
