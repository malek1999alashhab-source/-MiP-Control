import SwiftUI

@main
struct MiP_ControlApp: App {
    @StateObject private var ble = MiPBluetooth()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ble)
        }
    }
}
