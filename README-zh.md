# Emus

一款轻量的 macOS 菜单栏应用，一站式管理 iOS 和 Android 模拟器。

## 功能特性

- 🚀 从菜单栏快速访问所有已安装的模拟器
- 🍎 支持所有 Apple 模拟器：iPhone、iPad、Apple TV、Apple Watch、Vision Pro
- 🤖 支持 Android 模拟器
- ⚡ 一键启动任意模拟器
- 🔄 应用启动时自动开机指定模拟器（可选）
- 🌙 原生支持深色/浅色模式
- ⚙️ 可自定义 Android SDK 路径
- 🚀 可选登录时自动启动
- 🌍 多语言支持：英文、简体中文、繁体中文

## 安装

### 下载安装
从 [Releases](https://github.com/coderfee/Emus/releases) 页面下载最新版本。

### 源码编译
```bash
# 克隆仓库
git clone https://github.com/coderfee/Emus.git

# 用 Xcode 打开
cd Emus
open Emus.xcodeproj

# 使用 Xcode 编译运行
```

## 系统要求
- macOS 13.0+ (Ventura)
- Xcode（用于 iOS 模拟器）
- Android Studio（用于 Android 模拟器）

## 使用方法
1. 从应用程序文件夹启动 Emus
2. 点击菜单栏图标查看所有可用模拟器
3. 点击任意模拟器即可启动
4. 右键点击模拟器可访问更多选项（启动时自动开机）
5. 打开设置可配置 Android SDK 路径或开启登录时自动启动

## 开发说明
Emus 使用 SwiftUI 构建，完全基于原生系统框架：
- 无第三方依赖
- 100% 原生 SwiftUI 界面
- 使用 `simctl` 管理 iOS 模拟器
- 使用 `emulator` 命令行工具管理 Android 模拟器

## 许可证
MIT
