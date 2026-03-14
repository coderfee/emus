import SwiftUI

struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    private let windowWidth: CGFloat = 500
    private let windowHeight: CGFloat = 480

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            AboutSettingsTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: windowWidth, height: windowHeight)
        .id(appLanguage)
    }
}

private struct GeneralSettingsTab: View {
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    @AppStorage("androidSdkPath") private var androidSdkPath: String = "/Users/\(NSUserName())/Library/Android/sdk"
    @AppStorage("hideWatchSimulators") private var hideWatchSimulators: Bool = true
    @AppStorage("hideTVSimulators") private var hideTVSimulators: Bool = true
    @AppStorage("onlyShowLatest") private var onlyShowLatest: Bool = false
    
    @StateObject private var launchManager = LaunchAtLoginManager()
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchManager.isEnabled)
                    .onChange(of: launchManager.isEnabled) {
                        launchManager.toggle()
                    }
                
                Picker("Interface Language:", selection: $appLanguage) {
                    Text("System Default").tag("system")
                    Text("English").tag("en")
                    Text("Chinese (Simplified)").tag("zh-Hans")
                    Text("Chinese (Traditional)").tag("zh-Hant")
                }
            } header: {
                Text("General")
            }

            Section {
                Toggle("Hide Apple Watch Simulators", isOn: $hideWatchSimulators)
                Toggle("Hide Apple TV Simulators", isOn: $hideTVSimulators)
                Toggle("Only Show Latest System Versions", isOn: $onlyShowLatest)
                
                Text("Tip: Changes to filters will take effect after the next refresh.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } header: {
                Text("Device Filters")
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Path to Android SDK")
                        TextField("", text: $androidSdkPath)
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                validatePath()
                            }
                        
                        Button("Browse...") {
                            let panel = NSOpenPanel()
                            panel.allowsMultipleSelection = false
                            panel.canChooseDirectories = true
                            panel.canChooseFiles = false
                            if panel.runModal() == .OK {
                                let newPath = panel.url?.path ?? androidSdkPath
                                androidSdkPath = newPath
                                validatePath()
                            }
                        }
                        
                        Button("Reset") {
                            androidSdkPath = "/Users/\(NSUserName())/Library/Android/sdk"
                            validatePath()
                        }
                    }
                    
                    Text("Current emulator path: \(androidSdkPath)/emulator/emulator")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Paths")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.activate(ignoringOtherApps: true)
                launchManager.refreshStatus()
            }
        }
    }
    
    private func validatePath() {
        let currentPath = androidSdkPath
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                return SimulatorManager.validateAndroidSdkPath(currentPath)
            }.value

            if !result.isValid, let message = result.message {
                await MainActor.run {
                    _ = SimulatorManager.showAlert(
                        title: SimulatorManager.getLocString("Invalid Android SDK Path"),
                        message: message
                    )
                }
            }
        }
    }
}

private struct AboutSettingsTab: View {
    var body: some View {
        VStack(spacing: 16) {
            if let img = NSImage(named: "AppIcon") {
                Image(nsImage: img)
                    .resizable()
                    .frame(width: 80, height: 80)
            }

            Text("Emus")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Version \(version) (\(build))")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Link(destination: URL(string: "https://github.com/coderfee/emus")!) {
                HStack {
                    Image(systemName: "link")
                    Text("Project Homepage")
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
}
