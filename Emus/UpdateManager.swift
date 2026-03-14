import Foundation
import AppKit

enum UpdateManager {
    private struct GitHubRelease: Decodable {
        let tag_name: String
        let html_url: String
    }

    private enum UpdateError: Error {
        case invalidResponse
        case badStatusCode
        case invalidReleaseURL
    }

    static func checkForUpdates(manual: Bool, language: String) async {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            if manual {
                showCheckFailed(language: language)
            }
            return
        }

        do {
            let release = try await fetchLatestRelease()
            let latestVersion = normalizeVersion(release.tag_name)

            if compareVersions(latestVersion, currentVersion) == .orderedDescending {
                let title = localized("Update Available", language: language)
                let pattern = localized(
                    "A new version %@ is available. You are currently using %@.\n\nEmus will open the download page. Quit Emus before replacing the app in Applications."
                    ,
                    language: language
                )
                let message = String(format: pattern, latestVersion, currentVersion)

                let response = SimulatorManager.showAlert(
                    title: title,
                    message: message,
                    style: .informational,
                    buttons: [
                        localized("Download", language: language),
                        localized("Later", language: language)
                    ]
                )

                if response == .alertFirstButtonReturn {
                    guard let url = URL(string: release.html_url) else {
                        throw UpdateError.invalidReleaseURL
                    }
                    NSWorkspace.shared.open(url)
                }
            } else if manual {
                let title = localized("You are up to date.", language: language)
                let pattern = localized("Current version: %@.", language: language)
                let message = String(format: pattern, currentVersion)
                _ = SimulatorManager.showAlert(title: title, message: message, style: .informational)
            }
        } catch {
            if manual {
                showCheckFailed(language: language)
            }
        }
    }

    private static func showCheckFailed(language: String) {
        _ = SimulatorManager.showAlert(
            title: localized("Update Check Failed", language: language),
            message: localized("Unable to check for updates right now. Please try again later.", language: language)
        )
    }

    private static func localized(_ key: String, language: String) -> String {
        if language == "system" {
            return NSLocalizedString(key, comment: "")
        }
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }

    private static func fetchLatestRelease() async throws -> GitHubRelease {
        guard let url = URL(string: "https://api.github.com/repos/coderfee/emus/releases/latest") else {
            throw UpdateError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("EmusUpdateChecker", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 12

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw UpdateError.badStatusCode
        }

        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    private static func normalizeVersion(_ version: String) -> String {
        if version.hasPrefix("v") || version.hasPrefix("V") {
            return String(version.dropFirst())
        }
        return version
    }

    private static func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsParts = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let rhsParts = rhs.split(separator: ".").map { Int($0) ?? 0 }
        let maxCount = max(lhsParts.count, rhsParts.count)

        for index in 0..<maxCount {
            let lhsValue = index < lhsParts.count ? lhsParts[index] : 0
            let rhsValue = index < rhsParts.count ? rhsParts[index] : 0

            if lhsValue > rhsValue { return .orderedDescending }
            if lhsValue < rhsValue { return .orderedAscending }
        }

        return .orderedSame
    }
}
