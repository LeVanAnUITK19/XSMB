import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/regions.dart';
import '../../core/models/result_model.dart';
import '../../core/utils/transform_data.dart';
import '../../widgets/auto_check.dart';
import '../../widgets/result_table.dart';
import '../../widgets/single_choice.dart';
import '../../widgets/wait_page.dart';
import '../viewModels/home_viewmodel.dart';

/// View dùng chung cho tất cả regions.
/// Mỗi tab của bottom nav tạo 1 RegionView với RegionConfig tương ứng.
class RegionView extends StatefulWidget {
  final RegionConfig region;
  final ResultViewModel? viewModel;

  const RegionView({super.key, required this.region, this.viewModel});

  @override
  State<RegionView> createState() => _RegionViewState();
}

class _RegionViewState extends State<RegionView>
    with AutomaticKeepAliveClientMixin {
  late ResultViewModel _vm;
  String _selected = 'full';
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _repaintKey = GlobalKey();
  final _screenshotController = ScreenshotController();

  // Giữ state khi chuyển tab
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _vm = widget.viewModel ?? ResultViewModel(widget.region);
    _vm.addListener(_onVmChanged);
    _vm.load();
  }

  void _onVmChanged() {
    if (_vm.notFound) {
      _vm.notFound = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          _scaffoldKey.currentContext ?? context,
        ).showSnackBar(
          const SnackBar(
            content: Text('Không có dữ liệu cho ngày này'),
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    if (widget.viewModel == null) _vm.dispose();
    super.dispose();
  }

  // ─── Share as image ─────────────────────────────────────────────────────────

  Future<void> _shareAsImage(String displayDate) async {
    try {
      final provinces = _vm.result!.provinces;
      final tableData = transformData(provinces, _selected);

      final bytes = await _screenshotController.captureFromLongWidget(
        InheritedTheme.captureAll(
          context,
          Material(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: _buildShareTable(provinces, tableData, displayDate),
            ),
          ),
        ),
        pixelRatio: 2.0,
        context: context,
      );

      final safeDate = DateFormat('yyyy-MM-dd').format(_vm.currentDate);
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: '${widget.region.sharePrefix}_$safeDate.png',
          ),
        ],
        fileNameOverrides: ['${widget.region.sharePrefix}_$safeDate.png'],
        text: 'Kết quả ${widget.region.displayName} - $displayDate',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể chia sẻ: $e')));
      }
    }
  }

  Widget _buildShareTable(
    List<ProvinceResult> provinces,
    List<Map<String, dynamic>> tableData,
    String date,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: const Color.fromARGB(255, 243, 244, 161),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                'Kết quả ${widget.region.sharePrefix} - $date',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: _shareCell('Giải', isHeader: true)),
                ...provinces.map(
                  (p) => Expanded(
                    flex: 4,
                    child: _shareCell(p.province, isHeader: true),
                  ),
                ),
              ],
            ),
          ),
          ...tableData.map((row) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: _shareCell(row['label'] as String, isHeader: true),
                  ),
                  ...(row['values'] as List).map<Widget>((v) {
                    return Expanded(
                      flex: 4,
                      child: _shareCell(
                        v as String,
                        isG8: row['label'] == 'G8',
                        isDB: row['label'] == 'DB',
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _shareCell(
    String text, {
    bool isHeader = false,
    bool isG8 = false,
    bool isDB = false,
  }) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        color: isHeader ? Colors.yellow.shade100 : Colors.white,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isHeader ? 13 : 16,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.w900,
          color: isG8 || isDB ? Colors.red : Colors.black,
        ),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_vm.isLoading && _vm.result == null) {
      return WaitPage(region: widget.region);
    }

    if (_vm.error != null && _vm.result == null) {
      return Scaffold(
        key: _scaffoldKey,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_vm.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _vm.load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    if (_vm.result == null) {
      return Scaffold(
        key: _scaffoldKey,
        body: const Center(child: Text('Không có dữ liệu')),
      );
    }

    final provinces = _vm.result!.provinces;
    final tableData = transformData(provinces, _selected);
    final date = DateFormat(
      'EEEE, dd/MM/yyyy',
      'vi_VN',
    ).format(_vm.result!.date.toLocal());

    return Scaffold(
      key: _scaffoldKey,
      body: Column(
        children: [
          if (_vm.isRefreshing) const LinearProgressIndicator(),
          if (_vm.error != null)
            MaterialBanner(
              content: Text('${_vm.error} Đang hiển thị dữ liệu đã lưu.'),
              actions: [
                TextButton(onPressed: _vm.load, child: const Text('Tải lại')),
              ],
            ),
          if (provinces.isNotEmpty && provinces.first.specialSymbols.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.orange.shade50,
              padding: const EdgeInsets.all(8),
              child: Text(
                'Ký hiệu trúng ĐB: ${provinces.first.specialSymbols.join(' • ')}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          // ── Thanh ngày ────────────────────────────────────────────────────
          Container(
            color: const Color.fromARGB(255, 243, 244, 161),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            height: 48,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.calendar_today, size: 20),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _vm.currentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      locale: const Locale('vi', 'VN'),
                    );
                    if (picked != null) await _vm.loadByDate(picked);
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  onPressed: () => _shareAsImage(date),
                ),
              ],
            ),
          ),

          // ── Bảng kết quả ──────────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v < 0) {
                  // vuốt trái → ngày sau
                  final next = _vm.currentDate.add(const Duration(days: 1));
                  if (next.isAfter(DateTime.now())) return;
                  _vm.loadByDate(next);
                } else if (v > 0) {
                  // vuốt phải → ngày trước
                  _vm.loadByDate(
                    _vm.currentDate.subtract(const Duration(days: 1)),
                  );
                }
              },
              child: RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  color: Colors.white,
                  child: ResultTable(
                    provinces: provinces,
                    tableData: tableData,
                  ),
                ),
              ),
            ),
          ),

          // ── Bộ lọc số ─────────────────────────────────────────────────────
          Container(
            color: const Color.fromARGB(255, 243, 244, 161),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 44,
            child: Row(
              children: [
                const SizedBox(width: 6),
                SingleChoice(
                  value: 'full',
                  groupValue: _selected,
                  label: 'Đầy đủ',
                  onChanged: (val) => setState(() => _selected = val),
                ),
                const SizedBox(width: 16),
                SingleChoice(
                  value: '3',
                  groupValue: _selected,
                  label: '3 số',
                  onChanged: (val) => setState(() => _selected = val),
                ),
                const SizedBox(width: 16),
                SingleChoice(
                  value: '2',
                  groupValue: _selected,
                  label: '2 số',
                  onChanged: (val) => setState(() => _selected = val),
                ),
              ],
            ),
          ),

          // ── Nút dò vé ─────────────────────────────────────────────────────
          if (widget.region.supportsTicketChecking)
            SafeArea(
              child: Container(
                height: 58,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: InkWell(
                  onTap: () => showCheckTicketDialog(context, _vm),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.confirmation_number,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Dò Vé Số',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
