import SwiftUI

struct SettingsView: View {
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
                        
                        Button("Browse...") {
                            let panel = NSOpenPanel()
                            panel.allowsMultipleSelection = false
                            panel.canChooseDirectories = true
                            panel.canChooseFiles = false
                            if panel.runModal() == .OK {
                                androidSdkPath = panel.url?.path ?? androidSdkPath
                            }
                        }
                        
                        Button("Reset") {
                            androidSdkPath = "/Users/\(NSUserName())/Library/Android/sdk"
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
        .frame(width: 500, height: 450)
        .navigationTitle("Settings")
        .id(appLanguage)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.activate(ignoringOtherApps: true)
                launchManager.refreshStatus()
            }
        }
    }
}

#Preview {
    SettingsView()
}
