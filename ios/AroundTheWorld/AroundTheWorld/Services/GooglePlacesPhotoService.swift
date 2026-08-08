import Foundation

/// Venue photos via Google Places. Map search / pins stay on Apple MapKit.
struct GooglePlacesPhotoService: Sendable {
    enum ServiceError: LocalizedError {
        case missingAPIKey
        case badResponse

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "GOOGLE_PLACES_API_KEY is missing or still a placeholder"
            case .badResponse:
                return "Google Places returned an unexpected response"
            }
        }
    }

    private let apiKey: String?

    init(apiKey: String? = AppEnvironment.googlePlacesAPIKey) {
        self.apiKey = apiKey
    }

    /// Builds a Places Photo URL when a `photoReference` is known.
    func photoURL(photoReference: String, maxWidth: Int = 800) throws -> URL {
        guard let apiKey, !apiKey.isEmpty else { throw ServiceError.missingAPIKey }
        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/photo")!
        components.queryItems = [
            URLQueryItem(name: "maxwidth", value: String(maxWidth)),
            URLQueryItem(name: "photo_reference", value: photoReference),
            URLQueryItem(name: "key", value: apiKey),
        ]
        guard let url = components.url else { throw ServiceError.badResponse }
        return url
    }
}
