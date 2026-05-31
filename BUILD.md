# Build Guide · 构建指南

> [中文说明](#构建指南) below

This document covers how to build release artifacts for all supported platforms.

---

## Pre-flight Check

Ensure your Flutter environment is healthy:

```bash
flutter doctor -v
```

All platforms should show ✅ before proceeding.

---

## Windows

```bash
flutter build windows --release
```

- **Output**: `build/windows/x64/runner/Release/`
- **Executable**: `frp_gui.exe`
- ⚠️ Copy the `frp/` directory alongside the `.exe` after building

---

## macOS

```bash
flutter build macos --release
```

- **Output**: `build/macos/Build/Products/Release/frp_gui.app`
- ⚠️ Verify entitlements are configured in `macos/Runner/Release.entitlements`:
  - `com.apple.security.app-sandbox` = `false`
  - `com.apple.security.network.client` = `true`
  - `com.apple.security.network.server` = `true`

---

## Linux

```bash
flutter build linux --release
```

- **Output**: `build/linux/x64/release/bundle/`
- **Executable**: `frp_gui`
- ⚠️ Copy the `frp/` directory into the bundle folder

---

## Android

### APK

```bash
flutter build apk --release
```

- **Output**: `build/app/outputs/flutter-apk/app-release.apk`

### App Bundle (Google Play)

```bash
flutter build appbundle --release
```

- **Output**: `build/app/outputs/bundle/release/app-release.aab`

### Pre-release Checklist

1. Change `applicationId` in `android/app/build.gradle.kts` from `com.example.frp_gui` to your own
2. Configure a release signing key (see [Android Signing](#android-signing) below)

---

## iOS

```bash
# Unsigned .app (simulator only)
flutter build ios --release --no-codesign

# Signed IPA (requires Apple Developer account)
flutter build ipa
```

- **Output**: `build/ios/ipa/`

---

## Android Signing

You must sign your Android app with a release key before publishing. Debug keys are rejected by stores.

### 1. Generate a keystore

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

### 2. Create `android/key.properties`

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<path-to-keystore>/upload-keystore.jks
```

### 3. Update `android/app/build.gradle.kts`

Add before the `android` block:

```kotlin
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Then in `buildTypes.release`, replace the `signingConfig` line with:

```kotlin
signingConfig = signingConfigs.create("release") {
    keyAlias keystoreProperties['keyAlias']
    keyPassword keystoreProperties['keyPassword']
    storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
    storePassword keystoreProperties['storePassword']
}
```

---

## Platform-Specific Notes

| Platform | Key Consideration |
|----------|-------------------|
| Windows | VS 2022 with C++ workload required |
| macOS | Sandbox disabled in entitlements (required for subprocess execution) |
| Linux | `libgtk-3-dev`, `cmake`, `clang` must be installed |
| Android | `INTERNET` permission declared in `AndroidManifest.xml` |
| iOS | CocoaPods must be installed (`brew install cocoapods`) |

---

## 构建指南

本文档涵盖所有支持平台的 Release 构建方式。详细说明见上方英文部分。

### 构建命令速查

| 平台 | 命令 | 输出路径 |
|------|------|----------|
| Windows | `flutter build windows --release` | `build/windows/x64/runner/Release/` |
| macOS | `flutter build macos --release` | `build/macos/Build/Products/Release/` |
| Linux | `flutter build linux --release` | `build/linux/x64/release/bundle/` |
| Android APK | `flutter build apk --release` | `build/app/outputs/flutter-apk/` |
| Android AAB | `flutter build appbundle --release` | `build/app/outputs/bundle/release/` |
| iOS | `flutter build ipa` | `build/ios/ipa/` |

### Android 签名配置

参见上方 [Android Signing](#android-signing) 部分。
