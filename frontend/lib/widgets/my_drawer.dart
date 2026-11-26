import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants/app_config.dart';
import '../core/constants/regions.dart';
import '../features/views/schedule_view.dart';
import '../features/views/ticket_history_view.dart';
import '../features/views/stats_view.dart';
import '../features/views/help_view.dart';
import '../features/views/about_view.dart';
import '../features/views/prize_structure_view.dart';
import '../features/views/api_settings_view.dart';

class MyDrawer extends StatelessWidget {
  /// Callback để drawer yêu cầu home_view mở màn hình Dò Vé
  final VoidCallback? onCheckTicket;

  final RegionConfig region;
  final VoidCallback? onSettings;
  const MyDrawer({
    super.key,
    this.onCheckTicket,
    this.onSettings,
    this.region = Regions.mienBac,
  });

  Future<void> _shareApp(BuildContext context) async {
    await Share.share(
      'Tra cứu kết quả Xổ Số Việt Nam ngay trên điện thoại!\n'
      'Tải ứng dụng tại: ${AppConfig.playStoreUrl}',
      subject: 'Ứng dụng ${AppConfig.appName}',
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.of(context).pop(); // đóng drawer trước
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          _DrawerHeader(region: region),

          // ── Menu chính ───────────────────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'Cấu hình máy chủ',
                  onTap: () {
                    if (onSettings != null) {
                      Navigator.of(context).pop();
                      onSettings!();
                    } else {
                      _navigate(context, const ApiSettingsView());
                    }
                  },
                ),
                _DrawerItem(
                  icon: Icons.home_outlined,
                  label: 'Kết quả xổ số',
                  onTap: () => Navigator.of(context).pop(),
                ),
                if (region.supportsTicketChecking)
                  _DrawerItem(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Dò vé số',
                    onTap: () {
                      Navigator.of(context).pop();
                      onCheckTicket?.call();
                    },
                  ),
                if (region.supportsTicketChecking)
                  _DrawerItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'Lịch mở thưởng',
                    onTap: () =>
                        _navigate(context, ScheduleView(region: region)),
                  ),
                _DrawerItem(
                  icon: Icons.history,
                  label: 'Lịch sử dò vé',
                  onTap: () => _navigate(
                    context,
                    TicketHistoryView(regionKey: region.regionKey),
                  ),
                ),
                _DrawerItem(
                  icon: Icons.bar_chart,
                  label: 'Thống kê',
                  onTap: () => _navigate(
                    context,
                    StatsView(regionKey: region.regionKey),
                  ),
                ),
                if (region.supportsTicketChecking)
                  _DrawerItem(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Cơ cấu giải thưởng',
                    onTap: () =>
                        _navigate(context, PrizeStructureView(region: region)),
                  ),

                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Divider(color: Colors.grey.shade300),
                ),

                _DrawerItem(
                  icon: Icons.ios_share_outlined,
                  label: 'Chia sẻ ứng dụng',
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareApp(context);
                  },
                ),
                _DrawerItem(
                  icon: Icons.help_outline,
                  label: 'Trợ giúp & Phản hồi',
                  onTap: () => _navigate(context, const HelpView()),
                ),
                _DrawerItem(
                  icon: Icons.info_outline,
                  label: 'Giới thiệu',
                  onTap: () => _navigate(context, const AboutView()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header của Drawer ──────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final RegionConfig region;
  const _DrawerHeader({required this.region});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color.fromARGB(255, 240, 17, 1),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(region.assetImage, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            region.displayName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Phiên bản ${AppConfig.appVersion}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Item trong Drawer ─────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color.fromARGB(255, 200, 10, 0),
        size: 22,
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      dense: true,
      horizontalTitleGap: 12,
    );
  }
}
