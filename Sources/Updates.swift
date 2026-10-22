import AppKit

/// A published Pippy release that is newer than the running app.
struct ReleaseInfo: Equatable {
    let version: String
    let page: URL
    let download: URL
}

/// Asks GitHub for the latest published release. Nothing about the user is sent.
enum Updates {
    static let latestURL = URL(string: "https://api.github.com/repos/0xcrvpto/pippy/releases/latest")!
    static let assetSuffix = "-arm64.dmg"

    static func components(_ version: String) -> [Int] {
        version.trimmingCharacters(in: CharacterSet(charactersIn: "vV ")).split(separator: ".")
            .map { Int($0.prefix(while: \.isNumber)) ?? 0 }
    }

    static func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = components(candidate), b = components(current)
        for i in 0..<max(a.count, b.count) {
            let left = i < a.count ? a[i] : 0, right = i < b.count ? b[i] : 0
            if left != right { return left > right }
        }
        return false
    }

    /// Reads GitHub's release JSON; the download falls back to the release page when no Mac asset is attached.
    static func parse(_ data: Data) -> ReleaseInfo? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String,
              json["draft"] as? Bool != true, json["prerelease"] as? Bool != true,
              let pageString = json["html_url"] as? String, let page = URL(string: pageString) else { return nil }
        let assets = json["assets"] as? [[String: Any]] ?? []
        let asset = assets.first { ($0["name"] as? String)?.hasSuffix(assetSuffix) == true }
        let download = (asset?["browser_download_url"] as? String).flatMap(URL.init(string:)) ?? page
        return ReleaseInfo(version: tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV")), page: page, download: download)
    }
}

extension Notification.Name {
    static let pippyUpdateAvailable = Notification.Name("pippyUpdateAvailable")
}

/// Checks shortly after launch and then once a day; announces a newer release with `.pippyUpdateAvailable`.
final class UpdateChecker {
    private(set) var available: ReleaseInfo?
    private var timer: Timer?
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        return URLSession(configuration: configuration)
    }()

    func start() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in self?.check() }
        timer = Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in self?.check() }
    }

    /// `completion` receives the newer release, nil when up to date, or an error; it runs on the main queue.
    func check(completion: ((Result<ReleaseInfo?, Error>) -> Void)? = nil) {
        var request = URLRequest(url: Updates.latestURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Pippy/\(Feedback.appVersion)", forHTTPHeaderField: "User-Agent")
        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error { completion?(.failure(error)); return }
                guard (response as? HTTPURLResponse)?.statusCode == 200, let data, let release = Updates.parse(data) else {
                    completion?(.failure(URLError(.badServerResponse))); return
                }
                guard Updates.isNewer(release.version, than: Feedback.appVersion) else { completion?(.success(nil)); return }
                if self.available != release {
                    self.available = release
                    NotificationCenter.default.post(name: .pippyUpdateAvailable, object: self, userInfo: ["release": release])
                }
                completion?(.success(release))
            }
        }.resume()
    }

    deinit { timer?.invalidate() }
}
