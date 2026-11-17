class LocalKernelInfo {
  final bool installed;
  final String? version;
  final String? executablePath;
  final String platformArch;

  const LocalKernelInfo({
    required this.installed,
    required this.platformArch,
    this.version,
    this.executablePath,
  });
}

class FrpReleaseItem {
  final String tagName;
  final String assetName;
  final String downloadUrl;
  final int sizeBytes;
  final String publishedAt;
  final bool isFallback;

  const FrpReleaseItem({
    required this.tagName,
    required this.assetName,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.publishedAt,
    this.isFallback = false,
  });

  String get formattedSize {
    if (sizeBytes <= 0) return '约 16 MB';
    final mb = sizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}
