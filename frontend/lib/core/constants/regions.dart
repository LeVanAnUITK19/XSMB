class RegionConfig {
  final String regionKey, displayName, tabLabel, assetImage, sharePrefix;
  final List<String> apiBaseUrls;
  const RegionConfig({
    required this.regionKey,
    required this.displayName,
    required this.tabLabel,
    required this.assetImage,
    required this.sharePrefix,
    this.apiBaseUrls = const [],
  });
  bool get supportsTicketChecking => regionKey == 'mien-bac';
}

class Regions {
  static const mienBac = RegionConfig(
    regionKey: 'mien-bac',
    displayName: 'Xổ Số Miền Bắc',
    tabLabel: 'Miền Bắc',
    assetImage: 'assets/images/xsmb_logo.png',
    sharePrefix: 'XSMB',
  );
  static const all = [mienBac];
}
