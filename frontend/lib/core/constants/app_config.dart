/// Cấu hình toàn cục — thay đổi tại đây, áp dụng toàn app
class AppConfig {
  AppConfig._();

  /// Phiên bản hiển thị ở Drawer và màn hình Giới thiệu
  static const String appVersion = '1.0.0';

  /// Email nhận phản hồi từ người dùng
  static const String supportEmail = String.fromEnvironment('SUPPORT_EMAIL');

  /// Link Google Play để chia sẻ ứng dụng
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.myapp.kqxs.xsmb';

  /// Tên ứng dụng
  static const String appName = 'Xổ Số Miền Bắc';
}
