import Foundation
import Soft

// Add a constructor to create an Artist from the Spotify data model
extension Artist {
    init(spotifyArtist: SimplifiedArtist) {
        self.init(name: spotifyArtist.name)
    }
}

// Add a constructor to create a Track from the Spotify data model
extension Track {
    init(spotifyTrack: SimplifiedTrack) {
        self.init(
            artists: spotifyTrack.artists.map(Artist.init),
            id: spotifyTrack.id,
            name: spotifyTrack.name
        )
    }
}

// Add a constructor to create a PlayRecord from the Spotify data model
extension PlayRecord {
    init(spotifyRecord: PlayHistory) {
        self.init(
            track: Track(spotifyTrack: spotifyRecord.track),
            playedAt: spotifyRecord.playedAt
        )
    }
}

/// A Spotify client for querying a user's play history
public class SpotifyPlayHistoryClient: PlayHistoryInterface {
    private let requiredScope = "user-read-recently-played"
    private let token: TokenInfo
    private let refreshToken: String
    private let clientID: String
    private let clientSecret: String

    /// Creat a client
    ///
    /// - Parameter user: The user that we should be querying on
    public init(user: User, clientID: String, clientSecret: String) {
        self.token = TokenInfo(
            accessToken: user.accessToken,
            tokenType: "Bearer",
            scope: requiredScope,
            expiresAt: user.expiresAt,
            refreshToken: user.refreshAccessToken
        )
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.refreshToken = user.refreshAccessToken
    }

    /// Get the current user's recently played tracks
    ///
    /// - Parameter callback: Called upon completion
    public func getRecentlyPlayed(callback: @escaping ([PlayRecord]) -> Void) {
        // Check if token has expired
        guard !token.isExpired else {
            do {
                print("Refreshing token")
                let oauth = try SpotifyOAuth(
                    clientID: clientID, clientSecret: clientSecret,
                    // This will not be called
                    redirectURI: URL(string: "http://localhost:8080")!,
                    state: "", scope: requiredScope
                )
                // Refresh token if required
                // TODO: this logic is getting complicated, I should add tests
                oauth.refreshAccessToken(refreshToken: refreshToken) {
                    switch $0 {
                    case .success(let token):
                        let c = SpotifyClient(tokenInfo: token)
                        self.getRecentlyPlayed(
                            client: c,
                            callback: callback
                        )
                    case .failure(let error):
                        print("Refresh failed:", error)
                        callback([])
                    }
                }
            } catch {
                print("OAuth failed:", error)
                callback([])
            }
            return
        }
        // If not expired then fetch with token
        getRecentlyPlayed(
            client: SpotifyClient(tokenInfo: token),
            callback: callback
        )

    }

    private func getRecentlyPlayed(client: SpotifyClient, callback: @escaping ([PlayRecord]) -> Void) {
        client.currentUserRecentlyPlayed {
            switch $0 {
            case .success(let page):
                self.getPlayHistory(
                    client: client,
                    page: page,
                    items: page.items.map(PlayRecord.init),
                    requestCount: 0,
                    callback: callback
                )
            case .failure(let e):
                print("Spotify error:", e)
                callback([])
            }
        }
    }

    // TODO: don't just request all history because it could be huge
    // TODO: use after query with lastUpdate to ensure we only get the useful stuff
    private func getPlayHistory(client: SpotifyClient,
                                page: CursorBasedPage<PlayHistory>,
                                items: [PlayRecord], requestCount: Int,
                                callback: @escaping ([PlayRecord]) -> Void) {
        // To reduce going back in time forever we limit it to four requests.
        // In practice, usually the Spotify Web API does not return more than one
        // page anyway
        if requestCount > 4 {
            callback(items)
        }
        var items = items
        client.nextPage(page: page) {
            switch $0 {
            case .success(let page):
                items.append(contentsOf: page.items.map(PlayRecord.init))
                self.getPlayHistory(
                    client: client,
                    page: page,
                    items: items,
                    requestCount: requestCount + 1,
                    callback: callback
                )
            case .failure(let e):
                print("Spotify play history error:", e)
                callback(items)
            }
        }
    }
}
