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
    case shutdown
}

struct Device: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let type: DeviceType
    let isBooted: Bool
    let version: String    // e.g., "17.5"
    let platform: String   // e.g., "iOS", "tvOS"
}

@MainActor
class SimulatorManager: ObservableObject {
    @Published var devices: [Device] = []
    
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
                           let state = device["state"] as? String,
                           let isAvailable = device["isAvailable"] as? Bool,
                           isAvailable {
                            let fullName = "\(name) (\(osVersion))"
                            iosDevices.append(Device(
                                id: udid,
                                name: fullName,
                                type: .ios,
                                isBooted: state == "Booted",
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
            print("Error fetching iOS devices: \(error)")
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
                return lines.map { Device(id: $0, name: $0, type: .android, isBooted: false, version: "", platform: "Android") }
            }
        } catch {
            print("Error fetching Android devices: \(error)")
        }
        return []
    }
    
    func bootDevice(_ device: Device, mode: BootMode = .standard) {
        if mode == .shutdown && !device.isBooted { return }
        if mode == .standard && device.isBooted && device.type == .ios {
            activateSimulatorApp(path: openPath)
            return
        }

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
    
    private func bootIOS(_ device: Device, mode: BootMode) {
        let xcPath = xcrunPath
        let opPath = openPath
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: xcPath)
            
            switch mode {
            case .shutdown:
                process.arguments = ["simctl", "shutdown", device.id]
            case .wipe:
                process.arguments = ["simctl", "erase", device.id]
            default:
                process.arguments = ["simctl", "boot", device.id]
            }
            
            try? process.run()
            process.waitUntilExit()
            
            if case .shutdown = mode {
            } else {
                self.activateSimulatorApp(path: opPath)
            }
            
            DispatchQueue.main.async {
                self.fetchDevices()
            }
        }
    }
    
    private func bootAndroid(_ device: Device, mode: BootMode) {
        let emuPath = emulatorPath
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: emuPath)
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
            try? process.run()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.fetchDevices()
            }
        }
    }
}
