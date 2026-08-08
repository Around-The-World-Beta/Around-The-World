import Foundation

/// Reads runtime config from Info.plist / process environment.
/// Never commit real secrets — set via Xcode scheme env, xcconfig, or CI secrets.
enum AppEnvironment {
    /// Vapor API used by the native client.
    static var apiBaseURL: URL {
        if let raw = string("API_BASE_URL") ?? ProcessInfo.processInfo.environment["API_BASE_URL"],
           let url = URL(string: raw), !raw.isEmpty {
            return url
        }
        return URL(string: "http://127.0.0.1:8081")!
    }

    static var supabaseURL: URL? {
        guard let raw = string("SUPABASE_URL") ?? ProcessInfo.processInfo.environment["SUPABASE_URL"],
              !raw.isEmpty,
              !raw.contains("YOUR_PROJECT"),
              let url = URL(string: raw) else { return nil }
        return url
    }

    static var supabaseAnonKey: String? {
        guard let key = string("SUPABASE_ANON_KEY") ?? ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"],
              !key.isEmpty,
              !key.contains("YOUR_"),
              key != "REPLACE_ME" else { return nil }
        return key
    }

    /// Google Places (venue photos only — not used for map/search).
    static var googlePlacesAPIKey: String? {
        guard let key = string("GOOGLE_PLACES_API_KEY") ?? ProcessInfo.processInfo.environment["GOOGLE_PLACES_API_KEY"],
              !key.isEmpty,
              !key.contains("YOUR_"),
              key != "REPLACE_ME" else { return nil }
        return key
    }

    static var missingKeys: [String] {
        var missing: [String] = []
        if supabaseURL == nil { missing.append("SUPABASE_URL") }
        if supabaseAnonKey == nil { missing.append("SUPABASE_ANON_KEY") }
        if googlePlacesAPIKey == nil { missing.append("GOOGLE_PLACES_API_KEY") }
        return missing
    }

    static func resolvedAPIConfiguration() -> APIConfiguration {
        APIConfiguration(
            baseURL: apiBaseURL,
            timeoutInterval: 8
        )
    }

    private static func string(_ key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}
