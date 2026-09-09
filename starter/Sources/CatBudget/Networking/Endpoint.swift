import Foundation

/// A path plus query items, resolved against the Cat API base URL.
struct Endpoint {
    var path: String
    var queryItems: [URLQueryItem] = []

    static let baseURL = URL(string: "https://api.thecatapi.com/v1")!

    func url() throws -> URL {
        guard var components = URLComponents(
            url: Self.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { throw APIError.invalidURL }
        return url
    }

    static func breeds(limit: Int = 100) -> Endpoint {
        Endpoint(path: "breeds", queryItems: [
            URLQueryItem(name: "limit", value: String(limit))
        ])
    }

    static func searchBreeds(query: String) -> Endpoint {
        Endpoint(path: "breeds/search", queryItems: [
            URLQueryItem(name: "q", value: query)
        ])
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case http(status: Int)
    case decoding(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not build a valid request URL."
        case .http(let status):
            return "The Cat API returned HTTP \(status)."
        case .decoding:
            return "The Cat API response could not be decoded."
        }
    }
}
