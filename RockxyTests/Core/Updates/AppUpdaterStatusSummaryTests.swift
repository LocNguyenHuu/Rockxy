import Foundation
@testable import Rockxy
import Testing

@MainActor
struct AppUpdaterStatusSummaryTests {
    @Test("Update found creates a summary")
    func updateFoundCreatesSummary() {
        let updater = AppUpdater(configuration: makeConfiguration(appVersion: "0.12.0"))

        updater.recordUpdateFound(latestVersion: "0.17.0", fetchVersionsBehind: false)

        #expect(updater.updateStatusSummary?.title == "Update Available")
        #expect(updater.updateStatusSummary?.versionLine == "v0.12.0 -> v0.17.0")
        #expect(updater.updateStatusSummary?.badgeTitle == "Update Available")
    }

    @Test("No update clears the summary")
    func noUpdateClearsSummary() {
        let updater = AppUpdater(configuration: makeConfiguration(appVersion: "0.12.0"))
        updater.recordUpdateFound(latestVersion: "0.17.0", fetchVersionsBehind: false)

        updater.clearUpdateStatusSummary()

        #expect(updater.updateStatusSummary == nil)
    }

    @Test("Same or older latest version hides the summary")
    func sameOrOlderLatestVersionHidesSummary() {
        let same = AppUpdater.makeUpdateStatusSummary(
            currentVersion: "0.17.0",
            latestVersion: "0.17.0"
        )
        let older = AppUpdater.makeUpdateStatusSummary(
            currentVersion: "0.17.0",
            latestVersion: "0.12.0"
        )

        #expect(same == nil)
        #expect(older == nil)
    }

    @Test("Appcast count returns versions behind")
    func appcastVersionsBehindCount() {
        let data = Data(
            """
            <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
              <channel>
                <item><enclosure sparkle:shortVersionString="0.17.0" sparkle:version="26" /></item>
                <item><enclosure sparkle:shortVersionString="0.16.0" sparkle:version="25" /></item>
                <item><enclosure sparkle:shortVersionString="0.15.0" sparkle:version="24" /></item>
                <item><enclosure sparkle:shortVersionString="0.12.0" sparkle:version="15" /></item>
              </channel>
            </rss>
            """.utf8
        )

        let count = AppUpdater.versionsBehind(
            currentVersion: "0.12.0",
            latestVersion: "0.17.0",
            appcastData: data
        )

        #expect(count == 3)
    }

    @Test("Appcast summary uses latest release and update badge")
    func appcastSummaryUsesLatestReleaseAndBadge() {
        let data = Data(
            """
            <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
              <channel>
                <item><enclosure sparkle:shortVersionString="0.17.0" sparkle:version="26" /></item>
                <item><enclosure sparkle:shortVersionString="0.16.0" sparkle:version="25" /></item>
                <item><enclosure sparkle:shortVersionString="0.15.0" sparkle:version="24" /></item>
                <item><enclosure sparkle:shortVersionString="0.14.0" sparkle:version="23" /></item>
              </channel>
            </rss>
            """.utf8
        )

        let summary = AppUpdater.makeUpdateStatusSummary(
            currentVersion: "0.12.0",
            appcastData: data
        )

        #expect(summary?.latestVersion == "0.17.0")
        #expect(summary?.versionsBehind == 4)
        #expect(summary?.badgeTitle == "4 New Updates")
        #expect(summary?.countLine == "4 versions behind")
    }

    @Test("Single appcast update badge uses clean singular copy")
    func singleAppcastUpdateBadgeUsesCleanSingularCopy() {
        let data = Data(
            """
            <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
              <channel>
                <item><enclosure sparkle:shortVersionString="0.17.0" sparkle:version="26" /></item>
              </channel>
            </rss>
            """.utf8
        )

        let summary = AppUpdater.makeUpdateStatusSummary(
            currentVersion: "0.12.0",
            appcastData: data
        )

        #expect(summary?.versionsBehind == 1)
        #expect(summary?.badgeTitle == "1 New Update")
        #expect(summary?.countLine == "1 version behind")
    }

    @Test("Malformed appcast omits versions behind")
    func malformedAppcastOmitsCount() {
        let count = AppUpdater.versionsBehind(
            currentVersion: "0.12.0",
            latestVersion: "0.17.0",
            appcastData: Data("<rss><channel>".utf8)
        )

        #expect(count == nil)
    }

    private func makeConfiguration(appVersion: String) -> RockxyUpdateConfiguration {
        RockxyUpdateConfiguration(infoDictionary: [
            "RockxyUpdatesEnabled": "NO",
            "SUFeedURL": "https://example.com/appcast.xml",
            "SUPublicEDKey": "public-key",
            "CFBundleShortVersionString": appVersion,
            "CFBundleVersion": "1",
            "RockxyBuildReleaseDate": "2026-04-28T00:00:00Z",
        ])
    }
}
