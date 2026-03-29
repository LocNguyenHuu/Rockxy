import Foundation
import os

/// Validates and loads file content for Map Local rules.
/// Prevents path traversal, symlink abuse, and oversized file reads.
enum MapLocalFileValidator {
    // MARK: Internal

    /// Validates a Map Local file path and returns the file data if safe.
    /// Returns nil if the path is invalid, unreadable, or too large.
    static func loadFileData(at filePath: String) -> Data? {
        let expanded = (filePath as NSString).expandingTildeInPath
        let fileURL = URL(fileURLWithPath: expanded).standardizedFileURL

        let resolved = fileURL.resolvingSymlinksInPath()

        let fm = FileManager.default
        guard fm.fileExists(atPath: resolved.path) else {
            logger.warning("SECURITY: Map local file does not exist: \(resolved.path)")
            return nil
        }

        guard fm.isReadableFile(atPath: resolved.path) else {
            logger.warning("SECURITY: Map local file is not readable: \(resolved.path)")
            return nil
        }

        guard let attrs = try? fm.attributesOfItem(atPath: resolved.path),
              let fileSize = attrs[.size] as? UInt64 else
        {
            logger.warning("SECURITY: Cannot read attributes of map local file: \(resolved.path)")
            return nil
        }

        guard fileSize <= maxFileSize else {
            logger.warning("SECURITY: Map local file exceeds \(maxFileSize) bytes (\(fileSize)): \(resolved.path)")
            return nil
        }

        do {
            return try Data(contentsOf: resolved)
        } catch {
            logger.error("Failed to read map local file: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: Private

    private static let logger = Logger(subsystem: "com.amunx.Rockxy", category: "MapLocalFileValidator")

    /// Maximum file size allowed for Map Local responses (10 MB).
    private static let maxFileSize: UInt64 = 10 * 1024 * 1024
}
