import Foundation
import os.log

/// Structured launch diagnostics. Filter Console by subsystem `app.aroundtheworld.boot`.
enum BootLogger {
    private static let log = Logger(subsystem: "app.aroundtheworld.boot", category: "launch")

    static func step(_ name: String, _ detail: String = "") {
        if detail.isEmpty {
            log.info("▶ \(name, privacy: .public)")
        } else {
            log.info("▶ \(name, privacy: .public) — \(detail, privacy: .public)")
        }
        #if DEBUG
        print("[ATW Boot] \(name)\(detail.isEmpty ? "" : " — \(detail)")")
        #endif
    }

    static func done(_ name: String) {
        log.info("✓ \(name, privacy: .public)")
        #if DEBUG
        print("[ATW Boot] ✓ \(name)")
        #endif
    }

    static func fail(_ name: String, _ error: Error) {
        log.error("✗ \(name, privacy: .public): \(error.localizedDescription, privacy: .public)")
        #if DEBUG
        print("[ATW Boot] ✗ \(name): \(error.localizedDescription)")
        #endif
    }
}
