class ServerConfig {
  final String serverAddr;
  final int serverPort;
  final String token;

  const ServerConfig({
    this.serverAddr = '',
    this.serverPort = 7000,
    this.token = '',
  });

  bool get isConfigured => serverAddr.trim().isNotEmpty;

  String? validate() {
    if (serverAddr.trim().isEmpty) {
      return '请输入服务器地址';
    }
    if (serverPort < 1 || serverPort > 65535) {
      return '端口需在 1-65535 之间';
    }
    return null;
  }

  ServerConfig copyWith({
    String? serverAddr,
    int? serverPort,
    String? token,
  }) {
    return ServerConfig(
      serverAddr: serverAddr ?? this.serverAddr,
      serverPort: serverPort ?? this.serverPort,
      token: token ?? this.token,
    );
  }
}
