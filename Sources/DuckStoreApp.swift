import SwiftUI

@main
struct DuckStoreApp: App {
    @StateObject private var model = StoreModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
