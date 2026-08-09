import Foundation
import Vapor

/// Nine-county San Francisco Bay Area beta geography.
///
/// Counties: San Francisco, San Mateo, Santa Clara, Alameda, Contra Costa,
/// Marin, Solano, Napa, Sonoma.
enum BayAreaRegion {
    /// Slightly padded bbox covering Sonoma → South County / Gilroy and
    /// the Pacific coast → Livermore / East Contra Costa.
    static let minLatitude = 36.90
    static let maxLatitude = 38.85
    static let minLongitude = -123.15
    static let maxLongitude = -121.20

    static let counties: [String] = [
        "San Francisco",
        "San Mateo",
        "Santa Clara",
        "Alameda",
        "Contra Costa",
        "Marin",
        "Solano",
        "Napa",
        "Sonoma",
    ]

    static func contains(latitude: Double, longitude: Double) -> Bool {
        (minLatitude...maxLatitude).contains(latitude)
            && (minLongitude...maxLongitude).contains(longitude)
    }
}

/// Public metadata for clients (web + iOS) that need county / city lists.
struct BayAreaMetaResponse: Content {
    let region: String
    let counties: [String]
    let citiesByCounty: [String: [String]]
    let bounds: Bounds

    struct Bounds: Content {
        let minLatitude: Double
        let maxLatitude: Double
        let minLongitude: Double
        let maxLongitude: Double
    }

    static let `default` = BayAreaMetaResponse(
        region: "bay-area",
        counties: BayAreaRegion.counties,
        citiesByCounty: [
            "San Francisco": ["San Francisco"],
            "San Mateo": [
                "Daly City", "Pacifica", "San Mateo", "Redwood City",
                "Menlo Park", "Burlingame", "South San Francisco", "Half Moon Bay",
            ],
            "Santa Clara": [
                "San Jose", "Palo Alto", "Mountain View", "Sunnyvale",
                "Santa Clara", "Cupertino", "Milpitas", "Campbell", "Los Gatos", "Gilroy",
            ],
            "Alameda": [
                "Oakland", "Berkeley", "Alameda", "Fremont", "Hayward",
                "San Leandro", "Union City", "Livermore", "Pleasanton", "Emeryville",
            ],
            "Contra Costa": [
                "Walnut Creek", "Concord", "Richmond", "Martinez",
                "Antioch", "Pittsburg", "San Ramon", "Orinda", "El Cerrito",
            ],
            "Marin": [
                "San Rafael", "Mill Valley", "Novato", "Larkspur", "Sausalito", "San Anselmo",
            ],
            "Solano": ["Vallejo", "Fairfield", "Vacaville", "Benicia", "Suisun City"],
            "Napa": ["Napa", "American Canyon", "St. Helena", "Calistoga"],
            "Sonoma": ["Santa Rosa", "Petaluma", "Sonoma", "Rohnert Park", "Sebastopol"],
        ],
        bounds: .init(
            minLatitude: BayAreaRegion.minLatitude,
            maxLatitude: BayAreaRegion.maxLatitude,
            minLongitude: BayAreaRegion.minLongitude,
            maxLongitude: BayAreaRegion.maxLongitude
        )
    )
}
