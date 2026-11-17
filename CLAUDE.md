# CLAUDE.md

This file provides guidance when working with code in this repository.

## Common commands

Run these from the repository root with Flutter installed:

```bash
flutter pub get
flutter run -d windows
flutter analyze
flutter test
flutter test test/tunnel_storage_test.dart
flutter test test/widget_smoke_test.dart
flutter build windows --release
```

Supported desktop targets are `windows`, `macos`, and `linux`.

## Architecture

The codebase uses a layered structure under package `frp_gui`:

- `lib/main.dart` & `lib/app.dart`: Application entrypoint, desktop window lifecycle (`window_manager` close interception stopping `frpc` cleanly), persisted theme initialization, first-run OOBE routing, and `--autostart` silent connection support.
- `lib/models/`: Immutable domain models (`ServerConfig`, `TunnelProtocol`, `TunnelConfig`, `LocalKernelInfo`, `FrpReleaseItem`) encapsulating validation and TOML conversion while preserving custom proxy keys.
- `lib/services/`:
  - `frp_paths.dart`: Resolves workspace/executable-relative `frp/` paths and exposes `FrpPaths.debugBaseDirOverride` for isolated tests.
  - `config_repository.dart`: Reads and writes `frp/frpc.toml` (`includes = ["./tunnels/*.toml"]`, preserving custom sections such as `[webServer]`) and per-tunnel files in `frp/tunnels/` (`.toml` enabled, `.bak`/`.disabled` disabled).
  - `frp_process_service.dart`: Manages the `frpc` subprocess lifecycle, safe orphan PID cleanup, macOS quarantine/chmod preparation, 250 ms immediate-exit probe, log streaming, and timer-preserving config reload (`restartIfRunning`).
  - `kernel_download_service.dart`: Fetches GitHub releases (with offline fallback), streams archives in a background `Isolate` via `Dio` with optional mirror acceleration, extracts `frpc`, and atomically replaces the binary.
  - `auto_start_service.dart`: Configures login autostart across Windows (`HKCU\...\Run`), macOS (`LaunchAgents`), and Linux (`~/.config/autostart`).
  - `preferences_service.dart` & `log_service.dart`: `SharedPreferences` wrapper (theme + OOBE) and ANSI-sanitized bounded log buffer.
- `lib/controllers/`: `ChangeNotifier` state coordinators (`ThemeController`, `TunnelListController`, `ConnectionTimer`).
- `lib/ui/`:
  - `shell/`: `MainShellPage` (>600 px `NavigationRail`, <=600 px `NavigationBar`) and `DesktopTitleBar`.
  - `pages/`: Feature views (`home/`, `tunnels/`, `download/`, `logs/`, `settings/`, `oobe/`).
  - `widgets/` & `utils/`: Shared `showResponsiveModal`, `LabeledTextField`, `SettingTileCard`, and `AppToast`.

## Git & Runtime Files

- Runtime binaries, archives, PID files, and user `.toml` configs under `frp/` are ignored by `.gitignore`; only `frp/frpc.example.toml` is tracked.
- Standard `flutter_lints` rules (including `file_names` and `camel_case_types`) are enforced in `analysis_options.yaml`.
