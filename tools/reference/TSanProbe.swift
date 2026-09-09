import XCTest
@testable import CatBudget

final class TSanProbe: XCTestCase {
    func testConcurrentCacheWrites() async throws {
        StubURLProtocol.stub(match: "breeds", json: #"[{"id":"a","name":"A"}]"#)
        let client = APIClient(session: StubURLProtocol.makeSession(), apiKey: "k")

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<50 {
                group.addTask {
                    _ = try? await client.searchBreeds(query: "q\(index)")
                }
            }
        }
        StubURLProtocol.reset()
    }
}
