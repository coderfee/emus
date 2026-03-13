import SwiftUI

struct MenuView: View {
    @ObservedObject var simulatorManager: SimulatorManager
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    @Environment(\.locale) private var locale
    
    var body: some View {
        VStack {
            Section("iOS Simulators") {
                let iosDevices = simulatorManager.devices.filter { $0.type == .ios }
                if iosDevices.isEmpty {
                    Text("No iOS Simulators found")
                        .foregroundColor(.gray)
                } else {
                    ForEach(iosDevices) { device in
                        Menu {
                            Button {
                                simulatorManager.bootDevice(device, mode: .standard)
                            } label: {
                                Label("Boot", systemImage: "play.fill")
                            }
                            
                            Button {
                                simulatorManager.bootDevice(device, mode: .shutdown)
                            } label: {
                                Label("Shutdown", systemImage: "power")
                            }
                            
                            Button(role: .destructive) {
                                confirmWipe(for: device)
                            } label: {
                                Label("Erase Content and Settings", systemImage: "trash")
                            }
                        } label: {
                            Label(device.name, systemImage: iconName(for: device))
                        }
                    }
                }
            }
            
            Divider()
            
            Section("Android Emulators") {
                let androidDevices = simulatorManager.devices.filter { $0.type == .android }
                if androidDevices.isEmpty {
                    Text("No Android Emulators found")
                        .foregroundColor(.gray)
                } else {
                    ForEach(androidDevices) { device in
                        Menu {
                            Button {
                                simulatorManager.bootDevice(device, mode: .standard)
                            } label: {
                                Label("Default Boot", systemImage: "play.fill")
                            }
                            
                            Button {
                                simulatorManager.bootDevice(device, mode: .cold)
                            } label: {
                                Label("Cold Boot", systemImage: "snow")
                            }
                            
                            Button {
                                simulatorManager.bootDevice(device, mode: .headless)
                            } label: {
                                Label("Headless Mode", systemImage: "rectangle.dashed")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                confirmWipe(for: device)
                            } label: {
                                Label("Wipe Data", systemImage: "trash")
                            }
                        } label: {
                            Label(device.name, systemImage: iconName(for: device))
                        }
                    }
                }
            }
            
            Divider()
            
            Button("Refresh List") {
                simulatorManager.fetchDevices()
            }
            .keyboardShortcut("R")
            
            SettingsLink {
                Text("Settings")
            }
            .keyboardShortcut(",")
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .onAppear {
            simulatorManager.fetchDevices()
        }
    }
    
    private func iconName(for device: Device) -> String {
        let name = device.name.lowercased()
        if device.type == .ios {
            if name.contains("ipad") { return "ipad" }
            if name.contains("tv") { return "appletv" }
            if name.contains("watch") { return "applewatch" }
            if name.contains("vision") { return "visionpro" }
            return "iphone"
        } else {
            if name.contains("tv") { return "tv" }
            if name.contains("tablet") { return "ipad" }
            return "smartphone"
        }
    }

    private func confirmWipe(for device: Device) {
        let alert = NSAlert()
        
        alert.messageText = String(localized: "Wipe Confirmation", locale: locale)
        
        let messagePattern = String(localized: "Are you sure you want to wipe all data for '%@'? This action cannot be undone.", locale: locale)
        alert.informativeText = String(format: messagePattern, device.name)
        
        alert.alertStyle = .critical
        alert.addButton(withTitle: String(localized: "Wipe", locale: locale))
        alert.addButton(withTitle: String(localized: "Cancel", locale: locale))
        
        NSApp.activate(ignoringOtherApps: true)
        
        if alert.runModal() == .alertFirstButtonReturn {
            simulatorManager.bootDevice(device, mode: .wipe)
        }
    }
}
