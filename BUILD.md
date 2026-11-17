# Build Guide / 构建指南

This document covers how to build release artifacts for all supported desktop platforms (`Windows`, `macOS`, `Linux`).

---

## Pre-flight Check

Ensure your Flutter desktop toolchain is ready:

```bash
flutter doctor -v
flutter pub get
flutter analyze
flutter test
```

---

## Windows

```bash
flutter build windows --release
```

- **Output**: `build/windows/x64/runner/Release/`
- **Executable**: `frp_gui.exe`
- **Notes**: Requires Visual Studio 2022 with the "Desktop development with C++" workload. At runtime, `frp-gui` automatically creates `frp/` and `frp/tunnels/` next to the executable if not present.

---

## macOS

```bash
flutter build macos --release
```

- **Output**: `build/macos/Build/Products/Release/frp_gui.app`
- **Notes**: Verify entitlements in `macos/Runner/Release.entitlements`:
  - `com.apple.security.app-sandbox` = `false` (required to execute the external `frpc` subprocess)
  - `com.apple.security.network.client` = `true`
  - `com.apple.security.network.server` = `true`

---

## Linux

```bash
flutter build linux --release
```

- **Output**: `build/linux/x64/release/bundle/`
- **Executable**: `frp_gui`
- **Prerequisites** (Debian/Ubuntu):
  ```bash
  sudo apt install libgtk-3-dev cmake clang ninja-build pkg-config
  ```

---

## 构建命令速查

| 平台 | 构建命令 | 产物目录 |
|------|----------|----------|
| Windows | `flutter build windows --release` | `build/windows/x64/runner/Release/` |
| macOS | `flutter build macos --release` | `build/macos/Build/Products/Release/` |
| Linux | `flutter build linux --release` | `build/linux/x64/release/bundle/` |

## GitHub Actions 自动构建与发布

`.github/workflows/desktop.yml` 在 `master`、`dev` 推送、目标分支 PR 及手动触发时运行静态分析、串行测试和三个独立架构 Release 构建：Windows x64、Windows ARM64、macOS ARM64。使用各架构原生 runner 与 Flutter stable，安装包保留 14 天。

推送与 `pubspec.yaml` 版本一致的 tag（如版本 `1.0.0+1` 对应 `v1.0.0`）后，全部检查与构建通过才会自动创建 GitHub Release，上传以下文件：

- `frp-gui-windows-x64.zip`
- `frp-gui-windows-arm64.zip`
- `frp-gui-macos-arm64.zip`（仅本地 ad-hoc 签名，未经 Apple 公证）
- `SHA256SUMS.txt`

使用 Release AOT、图标 tree shaking 与 `--split-debug-info` 减小体积；Windows 排除 PDB、EXP、LIB，macOS 的 Mach-O 文件仅保留 ARM64 切片。调试符号另存为 CI artifact 保留 90 天，排查崩溃时应提前下载归档。不会混入 Release 安装包。

带连字符的 tag 会标记为预发布，且须与 pubspec 中的版本主体完全一致。工作流使用内置 `GITHUB_TOKEN`，仅发布任务需要 `contents: write`，无需额外配置密钥。安装包不包含用户配置和 FRP 内核，内核通过应用内下载。Linux 仍可本地构建，不在自动发布范围。
