import Foundation

/// A `URLProtocol` that answers requests from a table you set up in the test,
/// with an optional per-response delay.
///
/// Use it to build a `URLSession` that never touches the network:
///
///     let session = StubURLProtocol.makeSession()
///     StubURLProtocol.stub(path: "/v1/breeds/search", query: "q=sib",
///                          json: sibJSON, delay: .milliseconds(300))
///
/// Call `reset()` in `tearDown`.
final class StubURLProtocol: URLProtocol {
    struct Response {
        var statusCode: Int = 200
        var body: Data
        var delay: Duration = .zero
    }

    private static let lock = NSLock()
    private static var responses: [String: Response] = [:]

    /// Builds a session that routes every request through this stub.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    /// Registers a response. `match` is any substring of the full request URL,
    /// for example `"breeds/search?q=sib"`.
    static func stub(match: String, json: String, statusCode: Int = 200, delay: Duration = .zero) {
        lock.lock()
        defer { lock.unlock() }
        responses[match] = Response(
            statusCode: statusCode,
            body: Data(json.utf8),
            delay: delay
        )
    }

    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        responses.removeAll()
    }

    private static func response(for url: URL) -> Response? {
        lock.lock()
        defer { lock.unlock() }
        let absolute = url.absoluteString
        // Longest match wins, so a specific query beats a bare path.
        return responses
            .filter { absolute.contains($0.key) }
            .max { $0.key.count < $1.key.count }?
            .value
    }

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let stub = Self.response(for: url) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }

        let deliver = { [weak self] in
            guard let self else { return }
            let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: stub.statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            self.client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: stub.body)
            self.client?.urlProtocolDidFinishLoading(self)
        }

        if stub.delay == .zero {
            deliver()
        } else {
            Task {
                try? await Task.sleep(for: stub.delay)
                deliver()
            }
        }
    }

    override func stopLoading() {}
}
