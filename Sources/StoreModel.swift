import Foundation
import Security
import SwiftUI

// MARK: - Models (match the DuckStore server's JSON)

struct StoreApp: Identifiable, Decodable, Equatable {
    let file: String
    let name: String
    let version: String
    let bundle_id: String
    let size: String
    let mtime: Double
    var id: String { file }
}

struct HealthInfo: Decodable {
    let ok: Bool
    let days_left: Int?
    let last_error: String?
}

struct UploadResult: Decodable {
    let ok: Bool?
    let file: String?
    let name: String?
    let version: String?
    let signing: Bool?
    let t: Double?
    let error: String?
}

enum StoreError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        if case .message(let m) = self { return m }
        return nil
    }
}

// MARK: - Keychain (the admin token never sits in plain preferences)

enum Keychain {
    static func set(_ value: String, for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        if value.isEmpty { return }
        var add = query
        add[kSecValueData as String] = Data(value.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    static func get(_ key: String) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data else { return "" }
        return String(decoding: data, as: UTF8.self)
    }
}

// MARK: - Upload progress

final class ProgressDelegate: NSObject, URLSessionTaskDelegate {
    private let handler: (Double) -> Void
    init(_ handler: @escaping (Double) -> Void) { self.handler = handler }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didSendBodyData bytesSent: Int64, totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        guard totalBytesExpectedToSend > 0 else { return }
        let p = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        DispatchQueue.main.async { self.handler(p) }
    }
}

// MARK: - The store

@MainActor
final class StoreModel: ObservableObject {
    @Published var serverURL: String {
        didSet { UserDefaults.standard.set(serverURL, forKey: "serverURL") }
    }
    @Published var enrollCode: String {
        didSet { UserDefaults.standard.set(enrollCode, forKey: "enrollCode") }
    }
    @Published var adminToken: String {
        didSet { Keychain.set(adminToken, for: "adminToken") }
    }
    @Published var apps: [StoreApp] = []
    @Published var health: HealthInfo?
    @Published var loading = false
    @Published var errorText: String?

    init() {
        serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? ""
        enrollCode = UserDefaults.standard.string(forKey: "enrollCode") ?? ""
        adminToken = Keychain.get("adminToken")
    }

    var baseURL: URL? {
        var s = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if !s.lowercased().hasPrefix("http") { s = "https://" + s }
        while s.hasSuffix("/") { s.removeLast() }
        return URL(string: s)
    }

    func refresh() async {
        guard let base = baseURL else {
            apps = []
            health = nil
            return
        }
        loading = true
        defer { loading = false }
        do {
            let (data, resp) = try await URLSession.shared.data(from: base.appendingPathComponent("api/apps"))
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            apps = try JSONDecoder().decode([StoreApp].self, from: data)
            errorText = nil
        } catch {
            errorText = "Couldn\u{2019}t reach your DuckStore server. Check the address in Settings."
        }
        if let result = try? await URLSession.shared.data(from: base.appendingPathComponent("health")),
           let h = try? JSONDecoder().decode(HealthInfo.self, from: result.0) {
            health = h
        }
    }

    /// iOS installs apps from a signed manifest through this special link.
    func installURL(for app: StoreApp) -> URL? {
        guard let base = baseURL else { return nil }
        let manifest = base.appendingPathComponent("manifest")
            .appendingPathComponent(app.file + ".plist")
        return URL(string: "itms-services://?action=download-manifest&url=" + manifest.absoluteString)
    }

    func enrollURL() -> URL? {
        guard let base = baseURL else { return nil }
        var c = URLComponents(url: base.appendingPathComponent("enroll.mobileconfig"), resolvingAgainstBaseURL: false)
        if !enrollCode.isEmpty { c?.queryItems = [URLQueryItem(name: "code", value: enrollCode)] }
        return c?.url
    }

    func upload(fileURL: URL, progress: @escaping (Double) -> Void) async throws -> UploadResult {
        guard let base = baseURL else { throw StoreError.message("Set your server address in Settings first.") }
        guard !adminToken.isEmpty else { throw StoreError.message("Enter your admin token in Settings first.") }
        guard var comps = URLComponents(url: base.appendingPathComponent("upload"), resolvingAgainstBaseURL: false) else {
            throw StoreError.message("Bad server address.")
        }
        comps.queryItems = [URLQueryItem(name: "name", value: fileURL.lastPathComponent)]
        guard let url = comps.url else { throw StoreError.message("Bad server address.") }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(adminToken, forHTTPHeaderField: "X-Upload-Token")
        req.timeoutInterval = 1800
        let (data, resp) = try await URLSession.shared.upload(for: req, fromFile: fileURL,
                                                              delegate: ProgressDelegate(progress))
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        let result = try? JSONDecoder().decode(UploadResult.self, from: data)
        if status != 200 {
            throw StoreError.message(result?.error ?? "Upload failed (\(status)).")
        }
        return result ?? UploadResult(ok: true, file: fileURL.lastPathComponent, name: nil,
                                      version: nil, signing: false, t: nil, error: nil)
    }
}
