import 'tunnel_protocol.dart';

class TunnelConfig {
  static const Set<String> _managedKeys = {
    'name',
    'type',
    'localIP',
    'localPort',
    'remotePort',
    'customDomains',
    'subdomain',
    'secretKey',
  };

  final String name;
  final TunnelProtocol protocol;
  final String localIp;
  final int localPort;
  final int remotePort;
  final List<String> customDomains;
  final String subdomain;
  final String secretKey;
  final Map<String, dynamic> extraFields;
  final String? filePath;
  final String? fileName;
  final bool enabled;

  const TunnelConfig({
    this.name = '',
    this.protocol = TunnelProtocol.tcp,
    this.localIp = '127.0.0.1',
    this.localPort = 0,
    this.remotePort = 0,
    this.customDomains = const [],
    this.subdomain = '',
    this.secretKey = '',
    this.extraFields = const {},
    this.filePath,
    this.fileName,
    this.enabled = true,
  });

  static List<String> parseCustomDomains(Object? raw) {
    if (raw is List) {
      return raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      return raw
          .split(RegExp(r'[,，\s]+'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  static int _parsePort(Object? raw) {
    if (raw is int) return raw;
    return int.tryParse('${raw ?? ''}'.trim()) ?? 0;
  }

  factory TunnelConfig.fromTomlDocument(
    Map<dynamic, dynamic> rawDoc, {
    String? filePath,
    String? fileName,
    bool enabled = true,
  }) {
    final proxiesRaw = rawDoc['proxies'];
    final Map<dynamic, dynamic> source =
        (proxiesRaw is List && proxiesRaw.isNotEmpty && proxiesRaw.first is Map)
            ? proxiesRaw.first as Map<dynamic, dynamic>
            : rawDoc;

    final extras = <String, dynamic>{};
    for (final entry in source.entries) {
      final key = '${entry.key}';
      if (!key.startsWith('_') &&
          !_managedKeys.contains(key) &&
          entry.value != null) {
        extras[key] = entry.value;
      }
    }

    final ipText = '${source['localIP'] ?? ''}'.trim();

    return TunnelConfig(
      name: '${source['name'] ?? ''}'.trim(),
      protocol: TunnelProtocol.fromString('${source['type'] ?? 'tcp'}'),
      localIp: ipText.isEmpty ? '127.0.0.1' : ipText,
      localPort: _parsePort(source['localPort']),
      remotePort: _parsePort(source['remotePort']),
      customDomains: parseCustomDomains(source['customDomains']),
      subdomain: '${source['subdomain'] ?? ''}'.trim(),
      secretKey: '${source['secretKey'] ?? ''}'.trim(),
      extraFields: Map<String, dynamic>.unmodifiable(extras),
      filePath: filePath,
      fileName: fileName,
      enabled: enabled,
    );
  }

  String? validate() {
    if (name.trim().isEmpty) {
      return '请输入隧道名称';
    }
    if (localIp.trim().isEmpty) {
      return '请输入本地 IP';
    }
    if (localPort < 1 || localPort > 65535) {
      return '本地端口需在 1-65535 之间';
    }

    if (protocol.usesRemotePort) {
      if (remotePort < 1 || remotePort > 65535) {
        return '远程端口需在 1-65535 之间';
      }
    } else if (protocol.isHttpLike) {
      if (customDomains.isEmpty && subdomain.trim().isEmpty) {
        return '请填写自定义域名或子域名';
      }
    } else if (protocol.isSecretLike) {
      if (secretKey.trim().isEmpty) {
        return '请填写访问密钥 (secretKey)';
      }
    }
    return null;
  }

  String get targetSummary {
    if (protocol.isHttpLike) {
      final domainText = customDomains.isNotEmpty
          ? customDomains.join(', ')
          : subdomain.trim();
      return '域名: $domainText';
    }
    if (protocol.isSecretLike) {
      return '密钥: $secretKey';
    }
    return '远程端口: $remotePort';
  }

  Map<String, dynamic> toTomlProxyMap() {
    final proxy = <String, dynamic>{
      ...extraFields,
      'name': name.trim(),
      'type': protocol.value,
      'localIP': localIp.trim().isEmpty ? '127.0.0.1' : localIp.trim(),
      'localPort': localPort,
    };

    if (protocol.isHttpLike) {
      if (customDomains.isNotEmpty) {
        proxy['customDomains'] = customDomains;
      }
      if (subdomain.trim().isNotEmpty) {
        proxy['subdomain'] = subdomain.trim();
      }
    } else if (protocol.isSecretLike) {
      proxy['secretKey'] = secretKey.trim();
    } else {
      proxy['remotePort'] = remotePort;
    }

    return proxy;
  }

  Map<String, dynamic> toTomlDocumentMap() {
    return {
      'proxies': [toTomlProxyMap()],
    };
  }

  TunnelConfig copyWith({
    String? name,
    TunnelProtocol? protocol,
    String? localIp,
    int? localPort,
    int? remotePort,
    List<String>? customDomains,
    String? subdomain,
    String? secretKey,
    Map<String, dynamic>? extraFields,
    String? filePath,
    String? fileName,
    bool? enabled,
  }) {
    return TunnelConfig(
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      localIp: localIp ?? this.localIp,
      localPort: localPort ?? this.localPort,
      remotePort: remotePort ?? this.remotePort,
      customDomains: customDomains ?? this.customDomains,
      subdomain: subdomain ?? this.subdomain,
      secretKey: secretKey ?? this.secretKey,
      extraFields: extraFields ?? this.extraFields,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      enabled: enabled ?? this.enabled,
    );
  }
}
