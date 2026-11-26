import 'package:flutter/material.dart';
import '../../core/constants/regions.dart';
import '../../core/constants/api.dart';
import '../../widgets/my_drawer.dart';
import '../../widgets/auto_check.dart';
import '../viewModels/home_viewmodel.dart';
import 'region_view.dart';
import 'api_settings_view.dart';

class HomePageView extends StatefulWidget {
  final ResultViewModel? viewModel;
  const HomePageView({super.key, this.viewModel});
  @override
  State<HomePageView> createState() => _HomePageViewState();
}

class _HomePageViewState extends State<HomePageView> {
  late final ResultViewModel vm;
  bool configured = false;
  bool checking = true;
  @override
  void initState() {
    super.initState();
    vm = widget.viewModel ?? ResultViewModel(Regions.mienBac);
    if (widget.viewModel != null) {
      configured = true;
      checking = false;
    } else {
      _readConfig();
    }
  }

  Future<void> _readConfig() async {
    bool ready;
    try {
      await Api.baseUrl();
      ready = true;
    } catch (_) {
      ready = false;
    }
    if (mounted) {
      setState(() {
        configured = ready;
        checking = false;
      });
    }
  }

  @override
  void dispose() {
    if (widget.viewModel == null) vm.dispose();
    super.dispose();
  }

  Future<void> _settings() async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ApiSettingsView()));
    if (saved == true) await vm.resetData();
    await _readConfig();
    if (mounted && configured) await vm.load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Xổ Số Miền Bắc'),
      centerTitle: true,
      backgroundColor: const Color(0xFFF01101),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          tooltip: 'Tải kết quả mới',
          onPressed: vm.load,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Cấu hình máy chủ',
          onPressed: _settings,
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    ),
    drawer: MyDrawer(
      region: Regions.mienBac,
      onSettings: _settings,
      onCheckTicket: () => showCheckTicketDialog(context, vm),
    ),
    body: checking
        ? const Center(child: CircularProgressIndicator())
        : configured
        ? RegionView(region: Regions.mienBac, viewModel: vm)
        : Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/xsmb_logo.png', height: 220),
                  const SizedBox(height: 20),
                  const Text(
                    'Chào mừng đến với XSMB',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kết nối tới backend của bạn để xem kết quả và dò vé 5 chữ số.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _settings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Cấu hình máy chủ'),
                  ),
                ],
              ),
            ),
          ),
  );
}
