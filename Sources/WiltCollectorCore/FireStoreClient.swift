import Foundation

/// Response to list command for Firestore
///
/// - response: If we received a successful response
/// - error: The error that occurred
enum ListResponse<T: Decodable> {
    case response(ListHTTPResponse<T>)
    case error(Error)
}

/// The HTTP response from list in Firestore
public struct ListHTTPResponse<T : Decodable>: Decodable {
    let documents: [ListDocument<T>]
    let nextPageToken: String?

    var isAnotherPageAvailable: Bool {
        return nextPageToken != nil
    }

    func nextPage(client: FireStoreClient,
                  completionHandler: @escaping (ListResponse<T>) -> Void) {
        return client.list(
            pageToken: nextPageToken,
            completionHandler: completionHandler
        )
    }
}

/// A single document from list command in Firestore
public struct ListDocument<T : Decodable>: Decodable {
    let name: String
    let fields: T
}

/// An individual field in Firestore document will contain one of these values
enum FireStoreValue: Decodable, Equatable {
    case stringValue(String)
    case booleanValue(Bool)
    case integerValue(Int)
    case doubleValue(Double)
    case timestampValue(String)
    case bytesValue(String)
    case referenceValue(String)
    // TODO: add nullValue, geoPointValue, arrayValue and mapValue

    private enum CodingKeys: String, CodingKey {
        case stringValue
        case booleanValue
        case integerValue
        case doubleValue
        case timestampValue
        case bytesValue
        case referenceValue
    }

    enum FireStoreValueCodingError: Error {
        case decoding(String)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Find which value it contains
        if let value = try? container.decode(String.self, forKey: .stringValue) {
            self = .stringValue(value)
            return
        }
        if let value = try? container.decode(Bool.self, forKey: .booleanValue) {
            self = .booleanValue(value)
            return
        }
        if let value = try? container.decode(String.self, forKey: .integerValue),
            let intValue = Int(value) {
            self = .integerValue(intValue)
            return
        }
        if let value = try? container.decode(Double.self, forKey: .doubleValue) {
            self = .doubleValue(value)
            return
        }
        if let value = try? container.decode(String.self, forKey: .timestampValue) {
            self = .timestampValue(value)
            return
        }
        if let value = try? container.decode(String.self, forKey: .bytesValue) {
            self = .bytesValue(value)
            return
        }
        if let value = try? container.decode(String.self, forKey: .referenceValue) {
            self = .referenceValue(value)
            return
        }
        throw FireStoreValueCodingError.decoding("Bad values: \(dump(container))")
    }
}

/// Generic FireStore client for making web API requests
struct FireStoreClient {
    private let listUrl: String
    private let authenticationToken: String
    private let client: HTTPClient

    init(authenticationToken: String, projectID: String, collectionID: String,
         client: HTTPClient) {
        self.authenticationToken = authenticationToken
        self.client = client
        self.listUrl = "https://firestore.googleapis.com/v1beta1/projects/\(projectID)/databases/(default)/documents/\(collectionID)"
    }

    init(authenticationToken: String, projectID: String,
         collectionID: String) {
        self.init(
            authenticationToken: authenticationToken, projectID: projectID,
            collectionID: collectionID, client: SwiftyRequestClient()
        )
    }

    func list<T : Decodable>(pageToken: String? = nil,
                             completionHandler: @escaping (ListResponse<T>) -> Void) {
        let queryParam: String
        if let pageToken = pageToken {
            queryParam = "?pageToken=\(pageToken)"
        } else {
            queryParam = ""
        }
        client.get(
            url: listUrl + queryParam,
            headers: ["Authorization": "Bearer " + authenticationToken]
        ) { (body, response, error) in
            if let error = error {
                completionHandler(.error(error))
                return
            }
            guard let body = body else {
                fatalError("Response is empty")
            }
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(
                    ListHTTPResponse<T>.self,
                    from: body
                )
                completionHandler(.response(response))
            } catch {
                completionHandler(.error(error))
            }
        }
    }
}
