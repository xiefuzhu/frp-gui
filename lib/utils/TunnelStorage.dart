import 'dart:io';
import 'package:toml/toml.dart';

// frpc 主配置文件路径
const String frpcMainConfigPath = 'frp/frpc.toml';

// 单个隧道配置文件所在目录
const String frpcTunnelDirPath = 'frp/tunnels';

// 在主配置中引用隧道配置文件的匹配规则
const String frpcIncludePattern = './tunnels/*.toml';

// 确保 frp 配置目录结构存在且主配置包含 tunnels 引用
Future<void> ensureFrpConfigLayout() async {
  // 获取隧道配置目录对象
  final tunnelDir = Directory(frpcTunnelDirPath);

  // 如果目录不存在则递归创建
  if (!await tunnelDir.exists()) {
    await tunnelDir.create(recursive: true);
  }

  // 获取主配置文件对象
  final mainConfigFile = File(frpcMainConfigPath);

  // 如果主配置文件不存在，则创建一个最基础的 includes 配置
  if (!await mainConfigFile.exists()) {
    await mainConfigFile.writeAsString('includes = ["$frpcIncludePattern"]\n');
    return;
  }

  // 读取并解析现有主配置
  final document = await TomlDocument.load(frpcMainConfigPath);
  final config = Map<String, dynamic>.from(document.toMap());
  final includesRaw = config['includes'];
  final includes = <String>[];

  // 如果 includes 本身是数组，则全部转成字符串后加入列表
  if (includesRaw is List) {
    includes.addAll(includesRaw.map((item) => item.toString()));
  }

  // 如果主配置里还没包含 tunnels 的引用规则，则补上
  if (!includes.contains(frpcIncludePattern)) {
    includes.add(frpcIncludePattern);
    config['includes'] = includes;

    // 将更新后的配置重新写回主配置文件
    await mainConfigFile.writeAsString(
      TomlDocument.fromMap(config).toString(),
      mode: FileMode.write,
    );
  }
}

// 从完整路径中提取文件名
// 例如：C:/a/b/test.toml -> test.toml
String _fileNameFromPath(String path) {
  // 统一路径分隔符，避免 Windows 和 Unix 风格差异
  final normalized = path.replaceAll('\\', '/');
  return normalized.split('/').last;
}

// 获取文件主名（不带扩展名）
// 例如：test.toml -> test
String _fileStem(String path) {
  final fileName = _fileNameFromPath(path);
  final dotIndex = fileName.lastIndexOf('.');
  return dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
}

// 将字符串清洗成安全的文件名主名
// 仅保留字母、数字、下划线、短横线，其余字符替换为 _
String _sanitizeFileStem(String name) {
  final sanitized = name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  return sanitized.isEmpty ? 'tunnel' : sanitized;
}

// 从 TOML 解析结果中提取单个代理配置
// 如果存在 proxies 数组，则取第一个代理项；否则直接返回原始 map
Map<String, dynamic> _extractTunnelProxy(Map source) {
  final proxiesRaw = source['proxies'];
  if (proxiesRaw is List && proxiesRaw.isNotEmpty && proxiesRaw.first is Map) {
    return Map<String, dynamic>.from(proxiesRaw.first as Map);
  }
  return Map<String, dynamic>.from(source);
}

// 加载所有隧道配置文件
Future<List<Map<String, dynamic>>> loadTunnelConfigs() async {
  // 先确保配置目录和主配置准备好
  await ensureFrpConfigLayout();

  final tunnelDir = Directory(frpcTunnelDirPath);
  final entries = <Map<String, dynamic>>[];

  // 遍历隧道目录下的所有文件
  await for (final entity in tunnelDir.list(followLinks: false)) {
    // 只处理文件，跳过目录和其他实体
    if (entity is! File) {
      continue;
    }

    final path = entity.path;
    final fileName = _fileNameFromPath(path);
    final lower = fileName.toLowerCase();

    // .toml 视为启用状态
    final isEnabled = lower.endsWith('.toml');

    // .bak 或 .disabled 视为停用状态
    final isDisabled = lower.endsWith('.bak') || lower.endsWith('.disabled');

    // 非上述后缀的文件直接忽略
    if (!isEnabled && !isDisabled) {
      continue;
    }

    try {
      // 解析 TOML 文件
      final parsed = (await TomlDocument.load(path)).toMap();

      // 提取隧道主体配置
      final tunnel = _extractTunnelProxy(parsed);

      // 附加一些运行时元数据，方便 UI 层使用
      tunnel['_filePath'] = path;
      tunnel['_fileName'] = fileName;
      tunnel['_enabled'] = isEnabled;
      entries.add(tunnel);
    } catch (_) {
      // 忽略格式错误的隧道文件，继续加载其他文件
    }
  }

  // 按 name 字段升序排序，便于界面稳定展示
  entries.sort((a, b) => '${a['name'] ?? ''}'.compareTo('${b['name'] ?? ''}'));
  return entries;
}

// 通过修改文件后缀名来启用/停用隧道配置
// enabled=true  -> .toml
// enabled=false -> .bak
Future<void> toggleTunnelConfigBySuffix(String filePath, bool enabled) async {
  final currentFile = File(filePath);

  // 文件不存在则直接返回
  if (!await currentFile.exists()) {
    return;
  }

  final stem = _fileStem(filePath);
  final dir = currentFile.parent.path;
  final targetPath = '$dir${Platform.pathSeparator}$stem${enabled ? '.toml' : '.bak'}';

  // 如果目标路径和当前路径相同，说明无需修改
  if (targetPath == filePath) {
    return;
  }

  // 直接重命名文件，实现启用/停用切换
  await currentFile.rename(targetPath);
}

// 根据隧道 map 构建可写入 TOML 的数据结构
Map<String, dynamic> buildTunnelTomlBody(Map<String, dynamic> tunnel) {
  return {
    'proxies': [
      {
        // 隧道名称
        'name': tunnel['name'] ?? '',

        // 代理类型，默认 tcp
        'type': tunnel['type'] ?? 'tcp',

        // 本地 IP，默认 127.0.0.1
        'localIP': tunnel['localIP'] ?? '127.0.0.1',

        // 本地端口
        'localPort': tunnel['localPort'] ?? 0,

        // 远程端口
        'remotePort': tunnel['remotePort'] ?? 0,
      }
    ]
  };
}

// 保存隧道配置
// 如果传入 sourceFilePath，则视为“编辑已有配置”
// 如果未传入，则视为“新建配置”
Future<String> saveTunnelConfig(
  Map<String, dynamic> tunnel, {
  String? sourceFilePath,
  bool enabled = true,
}) async {
  // 先确保目录结构存在
  await ensureFrpConfigLayout();

  final dir = Directory(frpcTunnelDirPath);
  String targetPath;

  // 根据启用状态决定文件后缀
  final targetExt = enabled ? '.toml' : '.bak';

  // 如果有源文件路径，说明是在修改已有配置
  if (sourceFilePath != null && sourceFilePath.trim().isNotEmpty) {
    final stem = _fileStem(sourceFilePath);
    targetPath = '${dir.path}${Platform.pathSeparator}$stem$targetExt';
  } else {
    // 新建配置时，根据 name 生成文件名
    final baseStem = _sanitizeFileStem('${tunnel['name'] ?? ''}');
    targetPath = '${dir.path}${Platform.pathSeparator}$baseStem$targetExt';

    // 如果文件已存在，则自动追加递增编号避免重名
    var counter = 1;
    while (await File(targetPath).exists()) {
      targetPath = '${dir.path}${Platform.pathSeparator}${baseStem}_$counter$targetExt';
      counter++;
    }
  }

  // 如果源文件存在，并且目标路径不同，则删除旧文件
  // 这通常发生在编辑时启用状态改变，或文件名策略发生变化时
  final sourceFile = sourceFilePath == null ? null : File(sourceFilePath);
  if (sourceFile != null && await sourceFile.exists() && sourceFile.path != targetPath) {
    await sourceFile.delete();
  }

  // 将 tunnel map 转成 TOML 文本后写入目标文件
  final targetFile = File(targetPath);
  final tomlString = TomlDocument.fromMap(buildTunnelTomlBody(tunnel)).toString();
  await targetFile.writeAsString(tomlString, mode: FileMode.write);

  // 返回最终保存路径，便于外部继续使用
  return targetPath;
}

// 删除指定的隧道配置文件
Future<void> deleteTunnelConfig(String filePath) async {
  final file = File(filePath);
  if (await file.exists()) {
    await file.delete();
  }
}
