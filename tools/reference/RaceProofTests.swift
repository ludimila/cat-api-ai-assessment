import XCTest
@testable import CatBudget

@MainActor
final class RaceProofTests: XCTestCase {

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    func testLatestQueryWins() async throws {
        StubURLProtocol.stub(
            match: "breeds/search?q=sib",
            json: #"[{"id":"sibe","name":"Siberian"}]"#,
            delay: .milliseconds(400)
        )
        StubURLProtocol.stub(
            match: "breeds/search?q=siam",
            json: #"[{"id":"siam","name":"Siamese"}]"#,
            delay: .milliseconds(20)
        )

        let viewModel = BreedsViewModel(
            client: APIClient(session: StubURLProtocol.makeSession(), apiKey: "test-key")
        )

        viewModel.query = "sib"
        viewModel.query = "siam"

        try await Task.sleep(for: .milliseconds(900))

        XCTAssertEqual(viewModel.breeds.map(\.name), ["Siamese"])
    }
}
