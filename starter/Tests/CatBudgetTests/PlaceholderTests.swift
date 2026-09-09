import XCTest
@testable import CatBudget

/// Proves the test target is wired up and shows the stub in use.
/// Delete this file once you have real tests.
final class PlaceholderTests: XCTestCase {

    override func tearDown() {
        StubURLProtocol.reset()
        super.tearDown()
    }

    func testBreedDecodesSnakeCaseKeys() throws {
        let json = """
        [{"id":"siam","name":"Siamese","origin":"Thailand","life_span":"12 - 15","reference_image_id":"ai6Jps4sx"}]
        """
        let breeds = try APIClient.decoder.decode([Breed].self, from: Data(json.utf8))

        XCTAssertEqual(breeds.count, 1)
        XCTAssertEqual(breeds.first?.name, "Siamese")
        XCTAssertEqual(breeds.first?.referenceImageId, "ai6Jps4sx")
    }

    func testClientReturnsStubbedBreeds() async throws {
        StubURLProtocol.stub(
            match: "breeds/search",
            json: #"[{"id":"siam","name":"Siamese"}]"#
        )
        let client = APIClient(session: StubURLProtocol.makeSession(), apiKey: "test-key")

        let breeds = try await client.searchBreeds(query: "siam")

        XCTAssertEqual(breeds.map(\.name), ["Siamese"])
    }
}
