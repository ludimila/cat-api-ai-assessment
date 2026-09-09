import Foundation

/// Talks to The Cat API. Injectable `URLSession` so tests can stub transport.
struct APIClient {
    private let session: URLSession
    private let apiKey: String

    init(session: URLSession = .shared, apiKey: String = APIClient.keyFromBundle()) {
        self.session = session
        self.apiKey = apiKey
    }

    /// `GET /v1/breeds`
    func breeds() async throws -> [Breed] {
        try await load(Endpoint.breeds(), cacheKey: "")
    }

    /// `GET /v1/breeds/search?q=`
    func searchBreeds(query: String) async throws -> [Breed] {
        try await load(Endpoint.searchBreeds(query: query), cacheKey: query)
    }

    // MARK: - Transport

    private func load(_ endpoint: Endpoint, cacheKey: String) async throws -> [Breed] {
        let breeds: [Breed]

        if Self.usesFixtures(apiKey: apiKey) {
            breeds = try await Self.fixtureBreeds(matching: cacheKey)
        } else {
            var request = URLRequest(url: try endpoint.url())
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")

            let (data, response) = try await session.data(for: request)

            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw APIError.http(status: http.statusCode)
            }

            do {
                breeds = try Self.decoder.decode([Breed].self, from: data)
            } catch {
                throw APIError.decoding(underlying: error)
            }
        }

        BreedCache.shared.store(breeds, for: cacheKey)
        return breeds
    }

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    // MARK: - Configuration

    static func keyFromBundle() -> String {
        let value = Bundle.main.object(forInfoDictionaryKey: "CAT_API_KEY") as? String
        return value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// True when no usable key is configured. The app then serves the bundled
    /// fixture so a session can run with the Cat API unreachable or unpaid.
    static func usesFixtures(apiKey: String) -> Bool {
        apiKey.isEmpty || apiKey == "your-key-here"
    }

    private static func fixtureBreeds(matching query: String) async throws -> [Breed] {
        // Simulated latency. Without it the fixture path resolves instantly and
        // ordering bugs that show up against a real network stay hidden.
        try await Task.sleep(for: .milliseconds(Int.random(in: 80...600)))

        guard let url = Bundle.main.url(forResource: "breeds", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            throw APIError.http(status: 404)
        }
        let all = try decoder.decode([Breed].self, from: data)
        guard !query.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}
