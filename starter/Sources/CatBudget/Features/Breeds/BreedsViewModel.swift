import Foundation
import Observation

@MainActor
@Observable
final class BreedsViewModel {
    private(set) var breeds: [Breed] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var query: String = "" {
        didSet {
            guard query != oldValue else { return }
            queryChanged()
        }
    }

    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    func onAppear() {
        queryChanged()
    }

    private func queryChanged() {
        let requestedQuery = query
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let results = requestedQuery.isEmpty
                    ? try await client.breeds()
                    : try await client.searchBreeds(query: requestedQuery)
                self.breeds = results
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
