import Vapor

/// Ensures unhandled errors and AbortError responses are returned as clean JSON.
struct JSONErrorMiddleware: AsyncMiddleware {
    struct ErrorBody: Content {
        struct Payload: Content {
            let message: String
            let status: Int
        }

        let error: Payload
    }

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch {
            let status: HTTPResponseStatus
            let message: String

            if let abort = error as? any AbortError {
                status = abort.status
                message = abort.reason
            } else {
                status = .internalServerError
                message = request.application.environment.isRelease
                    ? "Internal server error"
                    : String(describing: error)
                request.logger.report(error: error)
            }

            let body = ErrorBody(error: .init(message: message, status: Int(status.code)))
            let response = Response(status: status)
            try response.content.encode(body, as: .json)
            return response
        }
    }
}
