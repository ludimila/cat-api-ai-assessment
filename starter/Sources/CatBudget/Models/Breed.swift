import Foundation

/// One cat breed as returned by `GET /v1/breeds` and `GET /v1/breeds/search`.
///
/// `referenceImageId` is the image the Cat API associates with the breed. The
/// favourites and votes endpoints both take an `image_id`, so this field is how
/// a breed row talks to those endpoints without rendering any image.
struct Breed: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let origin: String?
    let temperament: String?
    let description: String?
    let lifeSpan: String?
    let referenceImageId: String?
}
