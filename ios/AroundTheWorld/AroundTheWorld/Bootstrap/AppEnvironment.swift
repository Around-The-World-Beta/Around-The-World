import Foundation

/// Reads runtime config from Info.plist / process environment.
/// Never commit real secrets — set via Xcode scheme env, xcconfig, or CI secrets.
enum AppEnvironment {
    /// Vapor API used by the native client.
    static var apiBaseURL: URL {
        if let raw = cleaned("API_BASE_URL") ?? cleanedEnv("API_BASE_URL"),
           let url = URL(string: raw),
           url.scheme == "http" || url.scheme == "https" {
            return url
        }
        return URL(string: "http://127.0.0.1:8081")!
    }

    static var supabaseURL: URL? {
        guard let raw = cleaned("SUPABASE_URL") ?? cleanedEnv("SUPABASE_URL"),
              !raw.contains("YOUR_PROJECT"),
              let url = URL(string: raw) else { return nil }
        return url
    }

    static var supabaseAnonKey: String? {
        guard let key = cleaned("SUPABASE_ANON_KEY") ?? cleanedEnv("SUPABASE_ANON_KEY"),
              !key.contains("YOUR_"),
              key != "REPLACE_ME" else { return nil }
        return key
    }

    /// Google Places (venue photos only — not used for map/search).
    static var googlePlacesAPIKey: String? {
        guard let key = cleaned("GOOGLE_PLACES_API_KEY") ?? cleanedEnv("GOOGLE_PLACES_API_KEY"),
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

    /// Drops empty values and unresolved `$(BUILD_SETTING)` placeholders from Info.plist.
    private static func cleaned(_ key: String) -> String? {
        guard let raw = string(key)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              !raw.contains("$(") else { return nil }
        return raw
    }

    private static func cleanedEnv(_ key: String) -> String? {
        guard let raw = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              !raw.contains("$(") else { return nil }
        return raw
    }
}
