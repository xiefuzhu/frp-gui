import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../components/popupwindows/configModification.dart';
import '../../utils/ToastUtils.dart';
import '../../utils/TunnelStorage.dart';

/// OOBE 完成状态存储键
const String _oobeCompletedKey = 'oobe_completed';

/// 检查 OOBE 是否已完成
Future<bool> isOobeCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_oobeCompletedKey) ?? false;
}

/// 标记 OOBE 已完成
Future<void> setOobeCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_oobeCompletedKey, true);
}

/// OOBE 首次配置引导页面
class OobePage extends StatefulWidget {
  const OobePage({super.key});

  @override
  State<OobePage> createState() => _OobePageState();
}

class _OobePageState extends State<OobePage> {
  final TextEditingController _serverAddrController = TextEditingController();
  final TextEditingController _serverPortController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _serverAddrController.dispose();
    _serverPortController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    final serverAddr = _serverAddrController.text.trim();
    final serverPort = _serverPortController.text.trim();
    final token = _tokenController.text.trim();

    // 基本校验：服务器地址不能为空
    if (serverAddr.isEmpty) {
      if (mounted) {
        ToastUtils.showToast(context, '请输入服务器地址');
      }
      return;
    }

    setState(() => _saving = true);

    try {
      // 保存到 TOML 配置文件
      await saveServerConfig({
        'serverAddr': serverAddr,
        'serverPort': serverPort,
        'token': token,
      });

      // 标记 OOBE 已完成
      await setOobeCompleted();

      if (mounted) {
        ToastUtils.showToast(context, '配置已保存');
        // 跳转到主页面，并清除导航栈（不允许返回 OOBE）
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showToast(context, '保存失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 图标/标题区域
                  Icon(
                    Icons.router_rounded,
                    size: 72,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '欢迎使用 frp-gui',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '首次使用前，请配置 FRP 服务器连接信息',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 配置表单卡片
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withAlpha(100),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 服务器地址
                          configModification(
                            context,
                            _serverAddrController,
                            '服务器地址',
                            '例: 192.168.1.100 或 your-server.com',
                          ),
                          const SizedBox(height: 20),

                          // 服务器端口
                          configModification(
                            context,
                            _serverPortController,
                            '远程端口',
                            '例: 7000',
                          ),
                          const SizedBox(height: 20),

                          // Token
                          configModification(
                            context,
                            _tokenController,
                            'Token (可选)',
                            '服务器鉴权令牌',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 保存按钮
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveAndContinue,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_saving ? '正在保存...' : '完成配置'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
