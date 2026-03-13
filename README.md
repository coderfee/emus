# Emus

[简体中文](./README-zh.md)

A minimal macOS menu bar app for managing iOS and Android simulators/emulators in one place.

## Features

- 🚀 Quick access to all installed simulators from the menu bar
- 🍎 Support for all Apple simulators: iPhone, iPad, Apple TV, Apple Watch, Vision Pro
- 🤖 Support for Android emulators
- ⚡ One-click to launch any simulator
- 🔄 Auto-boot simulator on app launch (optional)
- 🌙 Native dark/light mode support
- ⚙️ Customizable Android SDK path
- 🚀 Optional launch at login
- 🌍 Multilingual support: English, Simplified Chinese, Traditional Chinese

## Installation

### From Release (Recommended)
1. Download the latest `.dmg` file from the [Releases](https://github.com/coderfee/emus/releases) page.
2. Drag **Emus** to your `Applications` folder.

> [!IMPORTANT]
> **About Code Signing**: As this app is not signed with an Apple Developer certificate, macOS may prevent it from opening. 
> To bypass this, **right-click** (or Control-click) the app icon in your Applications folder and select **Open**, then click **Open** again in the confirmation dialog.

### Build from source
```bash
# Clone the repository
git clone https://github.com/coderfee/Emus.git

# Open in Xcode
cd Emus
open Emus.xcodeproj

# Build and run with Xcode
```

## Requirements
- macOS 13.0+ (Ventura)
- Xcode (for iOS simulators)
- Android Studio (for Android emulators)

## Usage
1. Launch Emus from your Applications folder
2. Click the menu bar icon to see all available simulators
3. Click any simulator to launch it
4. Right-click a simulator to access additional options (auto-boot on launch)
5. Open Settings to configure Android SDK path or enable launch at login

## Development
Emus is built with SwiftUI and uses native system frameworks:
- No third-party dependencies
- 100% native SwiftUI interface
- Uses `simctl` for iOS simulator management
- Uses `emulator` command line tool for Android emulator management

## License
MIT
