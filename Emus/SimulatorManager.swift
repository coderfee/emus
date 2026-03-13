import Foundation
import SwiftUI
import Combine

enum DeviceType: Sendable {
    case ios
    case android
}

enum BootMode: Sendable {
    case standard
    case cold
    case headless
    case wipe
}

struct Device: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let type: DeviceType
    let version: String
    let platform: String
}

@MainActor
class SimulatorManager: ObservableObject {
    @Published var devices: [Device] = []
    @Published var lastErrorMessage: String?
    
    private nonisolated var androidSdkPath: String {
        UserDefaults.standard.string(forKey: "androidSdkPath") ?? "/Users/\(NSUserName())/Library/Android/sdk"
    }
    
    private nonisolated var hideWatch: Bool { UserDefaults.standard.bool(forKey: "hideWatchSimulators") }
    private nonisolated var hideTV: Bool { UserDefaults.standard.bool(forKey: "hideTVSimulators") }
    private nonisolated var onlyLatest: Bool { UserDefaults.standard.bool(forKey: "onlyShowLatest") }
    
    private nonisolated var emulatorPath: String { "\(androidSdkPath)/emulator/emulator" }
    private nonisolated let xcrunPath = "/usr/bin/xcrun"
    private nonisolated let openPath = "/usr/bin/open"
    
    func fetchDevices() {
        Task {
            let fetchedDevices = await Task.detached(priority: .userInitiated) {
                var allDevices: [Device] = []
                allDevices.append(contentsOf: self.fetchIOSDevices())
                allDevices.append(contentsOf: self.fetchAndroidDevices())
                allDevices.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                return allDevices
            }.value
            
            self.devices = fetchedDevices
        }
    }
    
    nonisolated private func fetchIOSDevices() -> [Device] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: xcrunPath)
        process.arguments = ["simctl", "list", "devices", "--json"]
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let deviceSets = json["devices"] as? [String: [[String: Any]]] {
                var iosDevices: [Device] = []
                for (runtime, devices) in deviceSets {
                    if hideWatch && runtime.lowercased().contains("watch") { continue }
                    if hideTV && runtime.lowercased().contains("tv") { continue }
                    
                    let platform: String
                    if runtime.contains("iOS") { platform = "iOS" }
                    else if runtime.contains("tvOS") { platform = "tvOS" }
                    else if runtime.contains("watchOS") { platform = "watchOS" }
                    else if runtime.contains("visionOS") { platform = "visionOS" }
                    else { platform = "Other" }
                    
                    let osVersion = runtime
                        .replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
                        .replacingOccurrences(of: "iOS-", with: "")
                        .replacingOccurrences(of: "tvOS-", with: "")
                        .replacingOccurrences(of: "watchOS-", with: "")
                        .replacingOccurrences(of: "visionOS-", with: "")
                        .replacingOccurrences(of: "-", with: ".")
                    
                    for device in devices {
                        if let name = device["name"] as? String,
                           let udid = device["udid"] as? String,
                           let isAvailable = device["isAvailable"] as? Bool,
                           isAvailable {
                            let fullName = "\(name) (\(osVersion))"
                            iosDevices.append(Device(
                                id: udid,
                                name: fullName,
                                type: .ios,
                                version: osVersion,
                                platform: platform
                            ))
                        }
                    }
                }
                
                if onlyLatest {
                    var latestVersions: [String: String] = [:]
                    for device in iosDevices {
                        let currentMax = latestVersions[device.platform] ?? "0"
                        if device.version.localizedStandardCompare(currentMax) == .orderedDescending {
                            latestVersions[device.platform] = device.version
                        }
                    }
                    iosDevices = iosDevices.filter { device in
                        device.version == latestVersions[device.platform]
                    }
                }
                
                return iosDevices
            }
        } catch {
            print("iOS Refresh Error: \(error.localizedDescription)")
        }
        return []
    }
    
    nonisolated private func fetchAndroidDevices() -> [Device] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: emulatorPath)
        process.arguments = ["-list-avds"]
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
                return lines.map { Device(id: $0, name: $0, type: .android, version: "", platform: "Android") }
            }
        } catch {
            print("Android Refresh Error: \(error.localizedDescription) Path: \(emulatorPath)")
        }
        return []
    }
    
    func bootDevice(_ device: Device, mode: BootMode = .standard) {
        switch device.type {
        case .ios:
            bootIOS(device, mode: mode)
        case .android:
            bootAndroid(device, mode: mode)
        }
    }
    
    nonisolated private func activateSimulatorApp(path: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = ["-a", "Simulator"]
        try? process.run()
    }
    
    nonisolated static func getLocString(_ key: String) -> String {
        let language = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        if language == "system" { return NSLocalizedString(key, comment: "") }
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return NSLocalizedString(key, comment: "") }
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }

    @MainActor
    static func showAlert(title: String, message: String, style: NSAlert.Style = .warning, buttons: [String] = [String(localized: "OK")]) -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        for button in buttons {
            alert.addButton(withTitle: button)
        }
        
        NSApp.activate(ignoringOtherApps: true)
        
        if let window = NSApp.keyWindow, window.isVisible {
            alert.beginSheetModal(for: window, completionHandler: nil)
            return .alertFirstButtonReturn
        } else {
            return alert.runModal()
        }
    }

    nonisolated static func validateAndroidSdkPath(_ path: String) -> (isValid: Bool, message: String?) {
        let emulatorPath = "\(path)/emulator/emulator"
        let fileManager = FileManager.default
        
        var isDir: ObjCBool = false
        if !fileManager.fileExists(atPath: path, isDirectory: &isDir) {
            return (false, getLocString("The directory does not exist."))
        }
        
        if !fileManager.fileExists(atPath: emulatorPath) {
            let pattern = getLocString("Cannot find 'emulator' executable at:\n%@\n\nPlease make sure the Android SDK path is correct.")
            return (false, String(format: pattern, emulatorPath))
        }
        
        if !fileManager.isExecutableFile(atPath: emulatorPath) {
            return (false, getLocString("The 'emulator' file exists but is not executable."))
        }
        
        return (true, nil)
    }
    
    nonisolated private func showError(_ message: String) {
        Task { @MainActor in
            _ = SimulatorManager.showAlert(
                title: SimulatorManager.getLocString("Error"),
                message: message
            )
        }
    }
    
    private func bootIOS(_ device: Device, mode: BootMode) {
        let xcPath = xcrunPath
        let opPath = openPath
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: xcPath)
            let errorPipe = Pipe()
            process.standardError = errorPipe
            
            switch mode {
            case .wipe:
                process.arguments = ["simctl", "erase", device.id]
            default:
                process.arguments = ["simctl", "boot", device.id]
            }
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus != 0 {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    self.showError("iOS Error: \(errorString)")
                } else {
                    self.activateSimulatorApp(path: opPath)
                }
            } catch {
                self.showError("Failed to run xcrun: \(error.localizedDescription)")
            }
        }
    }
    
    private func bootAndroid(_ device: Device, mode: BootMode) {
        let emuPath = emulatorPath
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: emuPath)
            let errorPipe = Pipe()
            process.standardError = errorPipe
            var args = ["-avd", device.id]
            
            switch mode {
            case .cold:
                args.append("-no-snapshot-load")
            case .headless:
                args.append("-no-window")
            case .wipe:
                args.append("-wipe-data")
            default:
                break
            }
            
            process.arguments = args
            
            do {
                try process.run()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if !process.isRunning && process.terminationStatus != 0 {
                        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                        let errorString = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                        self.showError("Android Error: \(errorString)")
                    }
                }
            } catch {
                self.showError("Failed to run emulator: \(error.localizedDescription)")
            }
        }
    }
}
