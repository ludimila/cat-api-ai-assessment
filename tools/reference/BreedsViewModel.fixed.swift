// Reference solution for the mandatory race fix. Interviewer copy — do not
// ship this in the starter.
//
// Three things changed against the starter:
//
//  1. The in-flight task is stored and cancelled when a new query arrives, so
//     a superseded request stops doing work instead of racing to the finish.
//  2. Search is an awaitable method rather than a fire-and-forget `Task` in
//     `didSet`, so a test can await it directly instead of sleeping and hoping.
//  3. A result is only applied when the query that produced it is still the
//     current one. Cancellation alone is not enough: a request can already be
//     past its last suspension point when `cancel()` lands.
//
// A candidate who does (1) and (3) but not (2) still passes the correctness
// bar. A candidate who only debounces has not fixed the race, they have made
// it rarer.

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
            startSearch(for: query)
        }
    }

    private let client: APIClient
    private var searchTask: Task<Void, Never>?

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    func onAppear() {
        startSearch(for: query)
    }

    /// Cancels any search in flight and starts a new one.
    func startSearch(for requestedQuery: String) {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            await self?.search(requestedQuery)
        }
    }

    /// Awaitable seam. Tests call this directly and await the result.
    func search(_ requestedQuery: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let results = requestedQuery.isEmpty
                ? try await client.breeds()
                : try await client.searchBreeds(query: requestedQuery)

            guard !Task.isCancelled, requestedQuery == query else { return }
            breeds = results
            isLoading = false
        } catch {
            guard !Task.isCancelled, requestedQuery == query else { return }
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    /// Waits for the search in flight, if any. Test helper.
    func waitForSearch() async {
        await searchTask?.value
    }
}
