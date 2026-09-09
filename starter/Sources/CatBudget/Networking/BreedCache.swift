import Foundation

/// In-memory cache of breed lists, keyed by search query.
///
/// Written to by `APIClient` after every successful decode.
final class BreedCache {
    static let shared = BreedCache()

    private var storage: [String: [Breed]] = [:]

    func store(_ breeds: [Breed], for key: String) {
        storage[key] = breeds
    }

    func breeds(for key: String) -> [Breed]? {
        storage[key]
    }

    func removeAll() {
        storage.removeAll()
    }
}
