import NIOConcurrencyHelpers
import Vapor

/// Fixed-window limit of requests per client IP.
///
/// Disabled when `RATE_LIMIT_DISABLED` is set (test helper). Limit comes from
/// `RATE_LIMIT_PER_MINUTE` (default 120).
struct RateLimitMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        if AuthConfiguration.rateLimitDisabled {
            return try await next.respond(to: request)
        }

        let limiter = request.application.rateLimiter
        let key = clientKey(for: request)
        let decision = limiter.allow(key: key, limit: AuthConfiguration.rateLimitPerMinute)

        guard decision.allowed else {
            var headers = HTTPHeaders()
            headers.replaceOrAdd(name: .retryAfter, value: "\(decision.retryAfterSeconds)")
            headers.replaceOrAdd(name: "X-RateLimit-Limit", value: "\(decision.limit)")
            headers.replaceOrAdd(name: "X-RateLimit-Remaining", value: "0")
            throw Abort(.tooManyRequests, headers: headers, reason: "Too many requests")
        }

        let response = try await next.respond(to: request)
        response.headers.replaceOrAdd(name: "X-RateLimit-Limit", value: "\(decision.limit)")
        response.headers.replaceOrAdd(name: "X-RateLimit-Remaining", value: "\(decision.remaining)")
        return response
    }

    private func clientKey(for request: Request) -> String {
        if let forwarded = request.headers.first(name: .xForwardedFor)?
            .split(separator: ",")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !forwarded.isEmpty
        {
            return forwarded
        }
        if let address = request.peerAddress {
            return address.ipAddress ?? address.description
        }
        return request.remoteAddress?.ipAddress ?? "unknown"
    }
}

struct RateLimitDecision: Sendable {
    let allowed: Bool
    let limit: Int
    let remaining: Int
    let retryAfterSeconds: Int
}

final class RateLimiter: @unchecked Sendable {
    private struct Window {
        var startedAt: Date
        var count: Int
    }

    private let lock = NIOLock()
    private let windowLength: TimeInterval = 60
    private var windows: [String: Window] = [:]

    func allow(key: String, limit: Int, now: Date = Date()) -> RateLimitDecision {
        lock.withLock {
            var window = windows[key] ?? Window(startedAt: now, count: 0)
            if now.timeIntervalSince(window.startedAt) >= windowLength {
                window = Window(startedAt: now, count: 0)
            }
            if window.count >= limit {
                windows[key] = window
                let retry = max(1, Int(windowLength - now.timeIntervalSince(window.startedAt)))
                return RateLimitDecision(allowed: false, limit: limit, remaining: 0, retryAfterSeconds: retry)
            }
            window.count += 1
            windows[key] = window
            return RateLimitDecision(
                allowed: true,
                limit: limit,
                remaining: max(0, limit - window.count),
                retryAfterSeconds: 0
            )
        }
    }
}

private struct RateLimiterKey: StorageKey {
    typealias Value = RateLimiter
}

extension Application {
    var rateLimiter: RateLimiter {
        if let existing = storage[RateLimiterKey.self] {
            return existing
        }
        let created = RateLimiter()
        storage[RateLimiterKey.self] = created
        return created
    }
}
