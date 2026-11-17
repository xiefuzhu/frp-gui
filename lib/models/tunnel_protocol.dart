enum TunnelProtocol {
  tcp,
  udp,
  http,
  https,
  stcp,
  xtcp,
  sudp;

  String get value => name;

  bool get isHttpLike =>
      this == TunnelProtocol.http || this == TunnelProtocol.https;

  bool get isSecretLike =>
      this == TunnelProtocol.stcp ||
      this == TunnelProtocol.xtcp ||
      this == TunnelProtocol.sudp;

  bool get usesRemotePort =>
      this == TunnelProtocol.tcp || this == TunnelProtocol.udp;

  static TunnelProtocol fromString(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    for (final item in TunnelProtocol.values) {
      if (item.name == normalized) {
        return item;
      }
    }
    return TunnelProtocol.tcp;
  }
}
