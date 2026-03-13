import SwiftUI

@main
struct EmusApp: App {
    @StateObject private var simulatorManager = SimulatorManager()
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    
    private var currentLocale: Locale {
        if appLanguage == "system" {
            return .current
        } else {
            return Locale(identifier: appLanguage)
        }
    }
    
    var body: some Scene {
        MenuBarExtra("Emus", systemImage: "ipad.and.iphone") {
            MenuView(simulatorManager: simulatorManager)
                .environment(\.locale, currentLocale)
        }
        
        Settings {
            SettingsView()
                .environment(\.locale, currentLocale)
        }
    }
}
