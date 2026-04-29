import CoreGraphics
import Foundation
@testable import Rockxy
import Sparkle
import Testing

@MainActor
struct SoftwareUpdateControllerTests {
    @Test("no-update context renders published release notes for the running build")
    func noUpdateContextUsesMatchingAppcastNotes() throws {
        let controller = SoftwareUpdateController(configuration: makeConfiguration(
            appVersion: "0.12.0",
            buildNumber: "15"
        ))
        let item = try makeAppcastItem(
            displayVersion: "0.12.0",
            buildNumber: "15",
            description: "<h1>Rockxy 0.12.0</h1><p>Notes</p>"
        )
        let error = NSError(
            domain: "RockxyTests.SoftwareUpdateController",
            code: 0,
            userInfo: [
                NSLocalizedDescriptionKey: "Rockxy 0.12.0 is already installed.",
                SPULatestAppcastItemFoundKey: item,
            ]
        )

        let context = controller.makeNoUpdateContext(from: error)

        #expect(context.currentVersion == "0.12.0 (15)")
        #expect(context.latestVersion == "0.12.0")
        #expect(
            context.releaseNotes
                == .html("<h1>Rockxy 0.12.0</h1><p>Notes</p>", baseURL: nil)
        )
        #expect(context.detailURL?.absoluteString == "https://example.com/releases/full")
    }

    @Test("no-update context avoids showing mismatched published notes for newer local builds")
    func noUpdateContextFallsBackForUnpublishedLocalBuild() throws {
        let controller = SoftwareUpdateController(configuration: makeConfiguration(
            appVersion: "0.12.1",
            buildNumber: "16"
        ))
        let item = try makeAppcastItem(
            displayVersion: "0.12.0",
            buildNumber: "15",
            description: "<h1>Rockxy 0.12.0</h1><p>Notes</p>"
        )
        let error = NSError(
            domain: "RockxyTests.SoftwareUpdateController",
            code: 0,
            userInfo: [
                NSLocalizedDescriptionKey: "Rockxy 0.12.1 is already installed.",
                SPULatestAppcastItemFoundKey: item,
            ]
        )

        let context = controller.makeNoUpdateContext(from: error)

        #expect(context.currentVersion == "0.12.1 (16)")
        #expect(context.latestVersion == "0.12.0")
        #expect(
            context.releaseNotes
                == .unavailable(
                    "Release notes for this local build are unavailable because this version is not published to the update feed yet."
                )
        )
        #expect(context.detailURL == AppUpdater.fullChangelogURL)
    }

    @Test("release note updates persist into later update phases")
    func releaseNotesPersistAcrossPhaseTransitions() {
        let controller = SoftwareUpdateController(configuration: makeConfiguration(
            appVersion: "0.12.0",
            buildNumber: "15"
        ))

        controller.showAvailable(context: makeAvailableContext(releaseNotes: .loading)) { _ in }
        defer { controller.dismiss() }

        controller.updateReleaseNotes(.plainText("Resolved release notes"))
        controller.showDownloading(cancel: {})

        guard case let .downloading(context, _, _) = controller.phase else {
            Issue.record("Expected downloading phase after starting the download")
            return
        }

        #expect(context.releaseNotes == .plainText("Resolved release notes"))
    }

    @Test("update stage descriptions refresh when the update phase advances")
    func updateStageDescriptionsRefreshAcrossTransitions() {
        let controller = SoftwareUpdateController(configuration: makeConfiguration(
            appVersion: "0.12.0",
            buildNumber: "15"
        ))

        controller.showAvailable(context: makeAvailableContext()) { _ in }
        defer { controller.dismiss() }

        controller.showReadyToInstall(reply: { _ in })

        guard case let .readyToInstall(readyContext) = controller.phase else {
            Issue.record("Expected ready-to-install phase")
            return
        }
        #expect(readyContext.updateStageDescription == "Downloaded")

        controller.showInstalling(applicationTerminated: false, retryTerminatingApplication: {})

        guard case let .installing(installingContext, applicationTerminated) = controller.phase else {
            Issue.record("Expected installing phase")
            return
        }
        #expect(applicationTerminated == false)
        #expect(installingContext.updateStageDescription == "Installing")
    }

    @Test("software update window centers on the active app window")
    func updateWindowFrameCentersOnAnchorWindow() {
        let visibleFrame = NSRect(x: 0, y: 0, width: 1_440, height: 900)
        let anchorFrame = NSRect(x: 100, y: 100, width: 1_200, height: 800)

        let frame = SoftwareUpdateWindowPositioning.positionedFrame(
            windowSize: SoftwareUpdateWindowPositioning.contentSize,
            anchorFrame: anchorFrame,
            visibleFrame: visibleFrame
        )

        #expect(frame.midX == anchorFrame.midX)
        #expect(frame.midY == anchorFrame.midY)
        #expect(frame.minX >= visibleFrame.minX)
        #expect(frame.maxX <= visibleFrame.maxX)
        #expect(frame.minY >= visibleFrame.minY)
        #expect(frame.maxY <= visibleFrame.maxY)
    }

    @Test("software update window falls back to screen centering")
    func updateWindowFrameCentersOnScreenWithoutAnchorWindow() {
        let visibleFrame = NSRect(x: 1_440, y: 0, width: 1_920, height: 1_080)

        let frame = SoftwareUpdateWindowPositioning.positionedFrame(
            windowSize: SoftwareUpdateWindowPositioning.contentSize,
            anchorFrame: nil,
            visibleFrame: visibleFrame
        )

        #expect(frame.midX == visibleFrame.midX)
        #expect(frame.midY == visibleFrame.midY)
    }

    @Test("software update window stays inside the display visible frame")
    func updateWindowFrameClampsToVisibleScreenArea() {
        let visibleFrame = NSRect(x: 0, y: 0, width: 1_440, height: 900)
        let anchorFrame = NSRect(x: 1_300, y: 750, width: 400, height: 300)

        let frame = SoftwareUpdateWindowPositioning.positionedFrame(
            windowSize: SoftwareUpdateWindowPositioning.contentSize,
            anchorFrame: anchorFrame,
            visibleFrame: visibleFrame
        )

        #expect(frame.maxX == visibleFrame.maxX)
        #expect(frame.maxY == visibleFrame.maxY)
        #expect(frame.minX >= visibleFrame.minX)
        #expect(frame.minY >= visibleFrame.minY)
    }
}

private func makeConfiguration(appVersion: String, buildNumber: String) -> RockxyUpdateConfiguration {
    RockxyUpdateConfiguration(infoDictionary: [
        "RockxyUpdatesEnabled": "NO",
        "SUFeedURL": "https://example.com/appcast.xml",
        "SUPublicEDKey": "public-key",
        "CFBundleShortVersionString": appVersion,
        "CFBundleVersion": buildNumber,
        "RockxyBuildReleaseDate": "2026-04-28T00:00:00Z",
    ])
}

private func makeAppcastItem(
    displayVersion: String,
    buildNumber: String,
    description: String
) throws -> SUAppcastItem {
    let itemDictionary: [String: Any] = [
        "title": "Rockxy \(displayVersion)",
        "link": "https://example.com/releases/\(displayVersion)",
        "description": [
            "content": description,
            "format": "html",
        ],
        "sparkle:fullReleaseNotesLink": "https://example.com/releases/full",
        "enclosure": [
            "url": "https://example.com/downloads/Rockxy-\(displayVersion).zip",
            "length": "123",
            "sparkle:version": buildNumber,
            "sparkle:shortVersionString": displayVersion,
        ],
    ]
    var failureReason: NSString?
    guard let item = SUAppcastItem(
        dictionary: itemDictionary,
        relativeTo: URL(string: "https://example.com/appcast.xml"),
        failureReason: &failureReason
    ) else {
        throw NSError(
            domain: "RockxyTests.SoftwareUpdateController",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: failureReason as String? ?? "Unable to create SUAppcastItem fixture.",
            ]
        )
    }
    return item
}

private func makeAvailableContext(
    releaseNotes: SoftwareUpdateReleaseNotesContent = .loading,
    stageDescription: String = "Not downloaded"
) -> SoftwareUpdateController.UpdateContext {
    SoftwareUpdateController.UpdateContext(
        title: "Rockxy 0.12.0",
        summary: "Rockxy 0.12.0 is now available.",
        currentVersion: "0.11.0",
        latestVersion: "0.12.0",
        buildNumber: "15",
        updateStageDescription: stageDescription,
        publishedDate: nil,
        releaseNotes: releaseNotes,
        detailURL: URL(string: "https://example.com/releases/0.12.0"),
        isInformationOnly: false,
        downloadSize: 123
    )
}
