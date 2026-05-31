# frp-gui

一个使用 Flutter 开发的 FRP（内网穿透）跨平台 GUI 管理客户端，支持 Windows / macOS / Linux / Android / iOS。

> [English version](./README.md) | [构建指南](./BUILD.md)

---

## 软件架构图

```
┌──────────────────────────────────────────────────────────┐
│                       UI 层 (Flutter)                     │
│  ┌────────┬──────────┬──────────┬────────┬───────────┐  │
│  │ OOBE   │  首页    │ 隧道管理  │ 内核下载 │   日志    │  │
│  │ 引导页  │ 启动/停止 │ CRUD配置 │ 自动更新 │ 实时输出  │  │
│  ├────────┴──────────┴──────────┴────────┴───────────┤  │
│  │              Settings · 服务器/主题/自启            │  │
│  ├─────────────────────────────────────────────────────┤  │
│  │          状态管理 (Provider + ValueNotifier)         │  │
│  ├─────────────────────────────────────────────────────┤  │
│  │  FrpService    DownloadManager   TunnelStorage      │  │
│  │  (进程管理)     (分块下载/解压)    (TOML 配置持久化)   │  │
│  ├─────────────────────────────────────────────────────┤  │
│  │              FRP 二进制 (frpc)                       │  │
│  │         外部子进程，stdout 实时捕获                     │  │
│  └─────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

---

## 截图

### macOS — 主界面

![macOS 主界面](image/mac.png)

### macOS — 内核下载

![内核下载](image/frp-core-dowload.png)

### macOS — 日志查看

![日志查看](image/log.png)

---

## 功能特性

| 模块 | 功能 |
|------|------|
| 🚀 **OOBE 引导** | 首次启动引导用户配置 FRP 服务器地址、远程端口和 Token |
| 🏠 **首页** | 一键启动/停止 FRP 守护进程，实时查看运行状态 |
| 🔗 **隧道管理** | 可视化 CRUD 代理配置（TOML 格式），支持添加/修改/删除/启停隧道规则 |
| 📥 **内核下载** | 自动从 GitHub Releases 获取最新 FRP 二进制，多线程分块下载 + 自动解压安装 |
| 📋 **日志查看** | 实时滚动显示 FRP 进程输出，ANSI 转义码已过滤 |
| 🎨 **外观设置** | 亮色/暗色/跟随系统主题切换 + 自定义主题色（Material You） |
| ⚙️ **服务器设置** | 配置 frp 远程服务器地址、端口及鉴权 Token |
| 🔄 **开机自启** | 桌面平台支持开机自动启动 FRP 穿透服务 |

### 亮点

- **自适应布局**：屏幕宽度 > 600px 显示 PC 侧边栏布局，≤ 600px 显示手机底部导航栏布局
- **平台智能适配**：自动检测系统架构（x64/ARM64），下载对应平台的 FRP 二进制
- **macOS 沙盒兼容**：自动移除 quarantine 标记 + 设置可执行权限
- **多语言支持**：中文（默认）+ 英文
- **OOBE 首次引导**：新用户首次打开自动进入配置向导，填写服务器信息后方可进入主界面

---

## 支持的平台

| 平台 | 状态 | 打包格式 |
|------|------|----------|
| Windows (x64) | ✅ 完善 | `.exe` (MSIX 可选) |
| macOS (Intel + Apple Silicon) | ✅ 完善 | `.app` |
| Linux (x64 + ARM64) | ✅ 完善 | 可执行文件 |
| Android | ✅ 完善 | `.apk` / `.aab` |
| iOS | ✅ 完善 | `.ipa` |
| Web | ⚠️ 未完善 | 仅脚手架 |

---

## 部署

### 下载

可在 GitHub 的 Release 页下载最新版本的 frp-gui，支持以下平台：

| 平台 | 格式 |
|------|------|
| Windows | `frp-gui-windows-x64.zip` |
| macOS (Intel) | `frp-gui-macos-x64.dmg` |
| macOS (Apple Silicon) | `frp-gui-macos-arm64.dmg` |
| Linux | `frp-gui-linux-x64.tar.gz` |
| Android | `frp-gui-android.apk` |

### 客户端运行

客户端直接在对应平台运行即可：

- **Windows**：解压后双击 `frp_gui.exe`
- **macOS**：将 `.app` 拖入 Applications 文件夹后打开
- **Linux**：终端执行 `./frp_gui`

#### 首次使用（OOBE）

首次打开应用时，会自动进入 **OOBE 配置引导页**，需要填写：

| 配置项 | 说明 | 示例 |
|--------|------|------|
| 服务器地址 | FRP 服务端的 IP 或域名 | `192.168.1.100` 或 `frp.example.com` |
| 远程端口 | FRP 服务端的绑定端口 | `7000` |
| Token | 服务端鉴权令牌（可选） | — |

填写完成点击「完成配置」后，配置将写入 `frp/frpc.toml`，之后自动跳转到主界面。后续启动将跳过 OOBE 直接进入主界面。

> **提示**：如需修改服务器配置，可随时在「设置 → 服务器设置」中调整。

#### 隧道管理

在「隧道管理」页面可以：

- **新建隧道**：填写名称、类型（tcp/udp/http 等）、本地 IP/端口、远程端口
- **编辑隧道**：点击已有隧道进行修改
- **启停隧道**：通过切换开关启用/停用单个隧道
- **删除隧道**：移除不再需要的隧道配置

每个隧道以独立 `.toml` 文件保存在 `frp/tunnels/` 目录下，启用状态通过文件后缀（`.toml` / `.bak`）控制。

#### 开机自启

桌面平台（Windows/macOS/Linux）支持开机自动启动 FRP 服务：

1. 进入「设置」页面
2. 打开「开机自启」开关
3. 下次系统启动时将自动运行 FRP 穿透服务

---

## 项目结构

```
frp-gui/
├── lib/
│   ├── main.dart                    # 应用入口，含 OOBE 检测
│   ├── routes/
│   │   └── index.dart               # 路由 & 主题配置
│   ├── pages/
│   │   ├── OOBE/                    # 首次配置引导页
│   │   ├── Main/                    # 主页面（自适应布局）
│   │   ├── Home/                    # 首页（启动/停止按钮）
│   │   ├── Tunnel/                  # 隧道管理页
│   │   ├── Download/                # 内核下载页
│   │   ├── Log/                     # 日志查看页
│   │   ├── Settings/                # 外观 · 服务器 · 自启设置
│   │   └── popupwindows/            # 弹窗组件
│   ├── components/                  # 各页面的子组件
│   └── utils/
│       ├── FrpService.dart          # FRP 进程管理（单例）
│       ├── DownloadManager.dart     # 下载管理器（单例）
│       ├── TunnelStorage.dart       # 隧道 & 服务器配置持久化
│       ├── ConfigStorage.dart       # 主题设置存储
│       ├── AutoStartManager.dart    # 开机自启管理
│       └── TerminalUtil.dart        # 日志输出工具
├── frp/
│   ├── frpc                         # FRP 客户端二进制（自动下载）
│   ├── frpc.toml                    # 主配置文件
│   └── tunnels/                     # 隧道配置目录
├── image/                           # 截图
├── android/                         # Android 平台
├── ios/                             # iOS 平台
├── macos/                           # macOS 平台
├── linux/                           # Linux 平台
├── windows/                         # Windows 平台
└── web/                             # Web 平台（未完善）
```

---

## 开发

### 环境要求

- **Flutter SDK** ≥ 3.10.7
- **Dart SDK** ≥ 3.10.7

平台特定构建工具：

| 目标平台 | 所需工具 |
|----------|----------|
| Android | Android Studio + Android SDK |
| iOS / macOS | Xcode 15+ + CocoaPods |
| Windows | Visual Studio 2022 (含「使用 C++ 的桌面开发」) |
| Linux | CMake + GTK 3 开发库 |

### 快速开始

```bash
# 1. 克隆项目
git clone <your-repo-url>
cd frp-gui

# 2. 安装依赖
flutter pub get

# 3. 运行（自动选择当前平台）
flutter run
```

### 构建发布

各平台 Release 构建命令详见 [BUILD.md](./BUILD.md)。

### 依赖项

主要依赖：

| 包名 | 用途 |
|------|------|
| `provider` | 状态管理 |
| `shared_preferences` | 本地持久化（OOBE 状态、主题） |
| `toml` | TOML 配置文件解析 |
| `window_manager` | 桌面窗口控制 |
| `xterm` | 终端模拟（日志） |
| `dynamic_color` | Material You 动态取色 |
| `archive` | 下载包解压 |

---

## 注意事项

1. **FRP 二进制需要单独下载**：首次使用请在「内核下载」页面自动从 GitHub Releases 下载对应平台的 `frpc`
2. **macOS 首次运行**：由于沙盒已禁用，首次启动可能需要手动允许网络访问
3. **Linux 依赖**：
   ```bash
   sudo apt install libgtk-3-dev cmake clang
   ```
4. **Windows**：需要安装 Visual Studio 2022 并勾选「使用 C++ 的桌面开发」

---

## License

本项目使用的 FRP 二进制来自 [fatedier/frp](https://github.com/fatedier/frp)，遵循其 Apache 2.0 License。
