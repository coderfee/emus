# Emus

[English](./README.md)

一个极简的 macOS 菜单栏应用，可在一个地方管理 iOS 和 Android 模拟器。

## 功能

- 🚀 从菜单栏快速访问所有已安装的模拟器
- 🍎 支持所有 Apple 模拟器：iPhone、iPad、Apple TV、Apple Watch、Vision Pro
- 🤖 支持 Android 模拟器
- ⚡ 一键启动任何模拟器
- 🔄 应用启动时可选自动引导模拟器
- 🌙 原生深色/浅色模式支持
- ⚙️ 可自定义 Android SDK 路径
- 🚀 可选的登录时启动
- 🌍 多语言支持：英文、简体中文、繁体中文

## 安装

### 从 Release 下载 (推荐)
1. 从 [Releases](https://github.com/coderfee/emus/releases) 页面下载最新的 `.dmg` 文件。
2. 将 **Emus** 拖到你的 `Applications` (应用程序) 文件夹。

> [!IMPORTANT]
> **关于签名**：由于该应用未经过 Apple 开发者证书签名，macOS 可能会阻止其打开。
> 若要绕过此限制，请在应用程序文件夹中 **右键点击** (或按住 Control 点击) 应用图标，选择 **“打开”**，然后在确认对话框中再次点击 **“打开”**。

### 从源码编译
```bash
# 克隆仓库
git clone https://github.com/coderfee/Emus.git

# 在 Xcode 中打开
cd Emus
open Emus.xcodeproj

# 使用 Xcode 构建并运行
```

## 要求
- macOS 13.0+ (Ventura)
- Xcode (用于 iOS 模拟器)
- Android Studio (用于 Android 模拟器)

## 使用
1. 从应用程序文件夹启动 Emus
2. 点击菜单栏图标查看所有可用模拟器
3. 点击任何模拟器以启动它
4. 右键点击模拟器以访问其他选项
5. 打开“设置”配置 Android SDK 路径或启用登录时启动

## 开发
Emus 使用 SwiftUI 构建并使用原生系统框架：
- 无第三方依赖
- 100% 原生 SwiftUI 界面
- 使用 `simctl` 进行 iOS 模拟器管理
- 使用 `emulator` 命令行工具进行 Android 模拟器管理

## 许可证
MIT
