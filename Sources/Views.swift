import SwiftUI
import UniformTypeIdentifiers

// MARK: - Look

extension Color {
    static let duckYellow = Color(red: 1.0, green: 0.82, blue: 0.25)
    static let duckOrange = Color(red: 1.0, green: 0.62, blue: 0.11)
    static let duckDeep = Color(red: 1.0, green: 0.48, blue: 0.0)
    static let duckBg = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(red: 0.09, green: 0.086, blue: 0.06, alpha: 1)
                                      : UIColor(red: 1.0, green: 0.97, blue: 0.88, alpha: 1)
    })
    static let card = Color(UIColor { t in
        t.userInterfaceStyle == .dark ? UIColor(red: 0.145, green: 0.137, blue: 0.10, alpha: 1) : UIColor.white
    })
}

private let tileColors: [(Color, Color)] = [
    (Color(red: 1.00, green: 0.70, blue: 0.28), Color(red: 1.00, green: 0.50, blue: 0.03)),
    (Color(red: 0.37, green: 0.92, blue: 0.83), Color(red: 0.08, green: 0.72, blue: 0.65)),
    (Color(red: 0.98, green: 0.44, blue: 0.52), Color(red: 0.88, green: 0.11, blue: 0.28)),
    (Color(red: 0.65, green: 0.55, blue: 0.98), Color(red: 0.43, green: 0.16, blue: 0.85)),
    (Color(red: 0.38, green: 0.65, blue: 0.98), Color(red: 0.15, green: 0.39, blue: 0.92)),
    (Color(red: 0.29, green: 0.87, blue: 0.50), Color(red: 0.08, green: 0.50, blue: 0.24))
]

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - The swimming duck

/// value == nil: the duck swims back and forth (used when progress can't be measured).
/// value 0...1: the duck rides the water line as it fills.
struct DuckProgress: View {
    var value: Double? = nil
    var done: Bool = false
    @State private var sweep = false

    private var fraction: Double { value ?? (sweep ? 0.92 : 0.08) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let x = max(0, min(w, w * fraction))
            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 12)
                    .offset(y: 30)
                Capsule()
                    .fill(LinearGradient(
                        colors: done ? [Color.green, Color(red: 0.02, green: 0.59, blue: 0.41)]
                                     : [Color(red: 0.22, green: 0.74, blue: 0.97), Color(red: 0.05, green: 0.65, blue: 0.91)],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(12, x), height: 12)
                    .offset(y: 30)
                Image("duck")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                    .rotationEffect(.degrees(value == nil ? (sweep ? 5 : -5) : 0))
                    .scaleEffect(done ? 1.2 : 1)
                    .offset(x: x - 19, y: done ? -6 : 0)
            }
        }
        .frame(height: 46)
        .padding(.horizontal, 10)
        .animation(.linear(duration: 0.25), value: value)
        .animation(.spring(response: 0.45, dampingFraction: 0.45), value: done)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { sweep = true }
        }
    }
}

// MARK: - One app in the list

enum InstallPhase { case idle, asking, installing, sent }

struct AppRow: View {
    let app: StoreApp
    let index: Int
    let phase: InstallPhase
    let onGet: () -> Void

    private var busy: Bool { phase == .asking || phase == .installing }

    private var message: String {
        switch phase {
        case .asking: return "Asking iOS to install\u{2026}"
        case .installing: return "Installing \u{2014} watch your Home Screen"
        case .sent: return "Sent to iOS \u{00B7} find it on your Home Screen"
        case .idle: return ""
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                let c = tileColors[index % tileColors.count]
                Text(String(app.name.prefix(1)).uppercased())
                    .font(.system(size: 25, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 58, height: 58)
                    .background(LinearGradient(colors: [c.0, c.1], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name).font(.headline).lineLimit(1)
                    Text("v\(app.version) \u{00B7} \(app.size)").font(.footnote).foregroundColor(.secondary)
                }
                Spacer(minLength: 8)
                Button(action: onGet) {
                    HStack(spacing: 6) {
                        if busy {
                            ProgressView().tint(.white).scaleEffect(0.8)
                            Text("Installing").font(.caption.bold())
                        } else {
                            Text("GET").font(.subheadline.bold())
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .frame(minWidth: 78, minHeight: 34)
                    .background(LinearGradient(colors: [.duckOrange, .duckDeep], startPoint: .top, endPoint: .bottom))
                    .clipShape(Capsule())
                    .shadow(color: Color.duckDeep.opacity(0.35), radius: 5, y: 3)
                }
                .buttonStyle(PressScaleStyle())
                .disabled(busy)
            }
            if phase != .idle {
                VStack(spacing: 2) {
                    DuckProgress(value: phase == .sent ? 1 : nil, done: phase == .sent)
                    Text(message).font(.caption.weight(.semibold)).foregroundColor(.secondary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 3, y: 1)
    }
}

// MARK: - Main screen

struct ContentView: View {
    @EnvironmentObject var model: StoreModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var query = ""
    @State private var phases: [String: InstallPhase] = [:]
    @State private var showSettings = false
    @State private var showAdd = false
    @State private var bob = false

    private var filtered: [StoreApp] {
        query.isEmpty ? model.apps : model.apps.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var pill: (String, Color)? {
        guard let h = model.health, let d = h.days_left else { return nil }
        if h.last_error != nil && d <= 14 { return ("Needs attention", .red) }
        if h.last_error != nil { return ("Last renewal failed \u{00B7} \(d) days left", .orange) }
        if d <= 14 { return ("Renews soon \u{00B7} \(d) days", .orange) }
        return ("Certificate valid \u{00B7} \(d) days", .green)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.duckBg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    header
                    VStack(spacing: 10) {
                        if model.baseURL == nil {
                            setupCard
                        } else {
                            searchField
                            if let e = model.errorText { notice(e) }
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { i, app in
                                AppRow(app: app, index: i, phase: phases[app.id] ?? .idle) { install(app) }
                            }
                            if filtered.isEmpty && !model.loading && model.errorText == nil { emptyState }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 110)
                }
            }
            .refreshable { await model.refresh() }

            Button { showAdd = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 62, height: 62)
                    .background(Circle().fill(LinearGradient(colors: [.duckOrange, .duckDeep], startPoint: .topLeading, endPoint: .bottomTrailing)))
                    .shadow(color: Color.duckDeep.opacity(0.45), radius: 10, y: 6)
            }
            .buttonStyle(PressScaleStyle())
            .padding(20)
            .accessibilityLabel("Add an app")
        }
        .task { await model.refresh() }
        .onChange(of: scenePhase) { p in
            if p == .active { Task { await model.refresh() } }
        }
        .sheet(isPresented: $showSettings) { SettingsSheet().environmentObject(model) }
        .sheet(isPresented: $showAdd) { AddSheet().environmentObject(model) }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) { bob = true }
        }
    }

    private var header: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                Image("duck")
                    .resizable().scaledToFit()
                    .frame(width: 74, height: 74)
                    .offset(y: bob ? -6 : 3)
                    .rotationEffect(.degrees(bob ? 3 : -3))
                Text("DuckStore")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.17, green: 0.16, blue: 0.15))
                Text("Your apps, your certificate.")
                    .font(.subheadline).foregroundColor(Color(red: 0.42, green: 0.33, blue: 0.07))
                if let p = pill {
                    HStack(spacing: 7) {
                        Circle().fill(p.1).frame(width: 8, height: 8)
                        Text(p.0).font(.caption.bold()).foregroundColor(Color(red: 0.29, green: 0.23, blue: 0.05))
                    }
                    .padding(.vertical, 5).padding(.horizontal, 12)
                    .background(Color.white.opacity(0.72))
                    .clipShape(Capsule())
                    .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
            .padding(.bottom, 26)

            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.29, green: 0.23, blue: 0.05))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.55))
                    .clipShape(Circle())
            }
            .buttonStyle(PressScaleStyle())
            .padding(.trailing, 14).padding(.top, 8)
            .accessibilityLabel("Settings")
        }
        .background(
            Color.duckYellow
                .clipShape(RoundedCorner(radius: 30, corners: [.bottomLeft, .bottomRight]))
                .ignoresSafeArea(edges: .top)
        )
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("Search apps", text: $query)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.secondary) }
            }
        }
        .padding(13)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
    }

    private var setupCard: some View {
        VStack(spacing: 10) {
            Text("Welcome to DuckStore").font(.headline)
            Text("Enter the address of your DuckStore server to see your apps.")
                .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
            Button("Open Settings") { showSettings = true }
                .font(.subheadline.bold()).foregroundColor(.white)
                .padding(.horizontal, 22).padding(.vertical, 10)
                .background(LinearGradient(colors: [.duckOrange, .duckDeep], startPoint: .top, endPoint: .bottom))
                .clipShape(Capsule())
        }
        .padding(22).frame(maxWidth: .infinity)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func notice(_ text: String) -> some View {
        Text(text).font(.footnote.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.card)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.duckOrange, lineWidth: 2))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image("duck").resizable().scaledToFit().frame(width: 70).opacity(0.7)
            Text(query.isEmpty ? "No apps yet" : "No matches").font(.headline)
            Text(query.isEmpty ? "Tap + to add your first app." : "Try a different name.")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .padding(.top, 30)
    }

    private func install(_ app: StoreApp) {
        guard let url = model.installURL(for: app) else { return }
        withAnimation(.spring()) { phases[app.id] = .asking }
        UIApplication.shared.open(url)
        // iOS performs the real install outside this app, so this animation is a "sent to iOS" cue,
        // not a live progress bar.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            if phases[app.id] == .asking { withAnimation { phases[app.id] = .installing } }
            try? await Task.sleep(nanoseconds: 10_200_000_000)
            withAnimation(.spring()) { phases[app.id] = .sent }
            try? await Task.sleep(nanoseconds: 4_200_000_000)
            withAnimation(.easeOut) { phases[app.id] = nil }
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                          cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}

// MARK: - Settings

struct SettingsSheet: View {
    @EnvironmentObject var model: StoreModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server"),
                        footer: Text("The HTTPS address where your DuckStore server is running.")) {
                    TextField("https://store.example.com", text: $model.serverURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
                Section(header: Text("Admin"),
                        footer: Text("Needed to add apps with the + button. Stored in the iOS Keychain.")) {
                    SecureField("Admin token", text: $model.adminToken)
                }
                Section(header: Text("This device"),
                        footer: Text("Register once so DuckStore apps can be installed on this iPhone or iPad.")) {
                    TextField("Invite code (if you have one)", text: $model.enrollCode)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    Button("Register this device") {
                        if let u = model.enrollURL() { UIApplication.shared.open(u) }
                    }
                    .disabled(model.baseURL == nil)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                        Task { await model.refresh() }
                    }
                }
            }
        }
    }
}

// MARK: - Add an app (the + button)

struct AddSheet: View {
    @EnvironmentObject var model: StoreModel
    @Environment(\.dismiss) private var dismiss
    @State private var picking = false
    @State private var working = false
    @State private var finished = false
    @State private var progress: Double? = 0
    @State private var status = ""
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 14) {
            Capsule().fill(Color.secondary.opacity(0.3)).frame(width: 42, height: 5).padding(.top, 8)
            Text("Add an app").font(.title3.bold())

            if working || finished {
                DuckProgress(value: finished ? 1 : progress, done: finished)
                Text(status).font(.footnote.weight(.semibold)).foregroundColor(.secondary)
            } else {
                Button { picking = true } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                            .frame(width: 54, height: 54)
                            .background(Circle().fill(LinearGradient(colors: [.duckOrange, .duckDeep], startPoint: .topLeading, endPoint: .bottomTrailing)))
                        Text("Choose an .ipa file").font(.headline).foregroundColor(.primary)
                        Text("From Files, iCloud Drive or your computer").font(.footnote).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 26)
                    .background(Color.duckYellow.opacity(0.18))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.duckOrange.opacity(0.7), style: StrokeStyle(lineWidth: 2.5, dash: [8, 6])))
                }
                .buttonStyle(PressScaleStyle())
            }

            if let e = errorText {
                Text(e).font(.footnote.weight(.semibold)).foregroundColor(.red).multilineTextAlignment(.center)
            }

            Button(finished ? "Done" : "Close") { dismiss() }
                .font(.subheadline.bold())
                .padding(.horizontal, 28).padding(.vertical, 10)
                .background(Color.secondary.opacity(0.15))
                .clipShape(Capsule())
                .disabled(working)
            Spacer(minLength: 0)
        }
        .padding(20)
        .fileImporter(isPresented: $picking, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in
            handle(result)
        }
    }

    private func handle(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        guard url.pathExtension.lowercased() == "ipa" else {
            errorText = "That isn\u{2019}t an .ipa file."
            return
        }
        errorText = nil
        working = true
        progress = 0
        status = "Starting upload\u{2026}"
        Task { @MainActor in
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            do {
                let r = try await model.upload(fileURL: url) { p in
                    progress = p
                    status = "Uploading \(Int(p * 100))%"
                }
                if r.signing == true, let f = r.file {
                    progress = nil
                    status = "Uploaded. Signing it for your devices\u{2026}"
                    let since = (r.t ?? 0) - 1
                    var tries = 0
                    while tries < 90 {
                        await model.refresh()
                        if model.apps.contains(where: { $0.file == f && $0.mtime >= since }) { break }
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        tries += 1
                    }
                } else {
                    await model.refresh()
                }
                working = false
                finished = true
                status = "Added \(r.name ?? "app")" + (r.version.map { " \u{00B7} v\($0)" } ?? "")
                try? await Task.sleep(nanoseconds: 2_200_000_000)
                dismiss()
            } catch {
                working = false
                progress = 0
                errorText = error.localizedDescription
            }
        }
    }
}
