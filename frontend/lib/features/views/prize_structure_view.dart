import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/regions.dart';
import '../../core/lottery/prize_rule.dart';

class PrizeStructureView extends StatelessWidget {
  final RegionConfig region;
  const PrizeStructureView({super.key, this.region = Regions.mienBac});
  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.decimalPattern('vi_VN');
    return Scaffold(
      appBar: AppBar(title: const Text('Cơ cấu giải thưởng XSMB')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Vé truyền thống 5 chữ số, mệnh giá 10.000đ. Cơ cấu tham chiếu Công ty XSKT Quảng Ninh. Mức Đặc biệt/phụ Đặc biệt có thể khác theo đơn vị và đợt phát hành; khi dò hãy nhập đúng mức in trên vé.',
              ),
            ),
          ),
          ...TraditionalPrizeRules.allMainPrizes.map(
            (rule) => Card(
              child: ListTile(
                title: Text(rule.name),
                subtitle: Text(
                  '${rule.resultCount} lần quay • ${rule.matchDigits} chữ số',
                ),
                trailing: Text('${money.format(rule.amount)}đ'),
              ),
            ),
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Giải phụ Đặc biệt tham chiếu: 25.000.000đ. Cần trùng 5 số ĐB và ký hiệu hợp lệ khác các ký hiệu trúng ĐB.\n\nKhuyến khích: 40.000đ khi trùng 2 số cuối ĐB. Một vé có thể trúng nhiều hạng và được cộng đủ.\n\nBộ 15 ký hiệu thường có 6 ký hiệu trúng ĐB; bộ 20 ký hiệu có 8. Thiếu ký hiệu hoặc danh sách chưa đủ thì không kết luận giải ĐB/phụ ĐB.',
              ),
            ),
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Thuế TNCN ước tính: từ 01/07/2026, 10% phần tổng thưởng vượt 20 triệu đồng trên một vé; ngày trả thưởng là căn cứ tính thuế.\n\nKiểm tra đúng ngày trên vé, giữ vé gốc nguyên vẹn. Thời hạn lĩnh thưởng theo thể lệ của đơn vị phát hành.',
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Nguồn cơ cấu: XSKT Quảng Ninh'),
            onTap: () => launchUrl(
              Uri.parse(
                'https://www.xosoquangninh.com.vn/xskt/loai-hinh-xo-so/xo-so-truyen-thong',
              ),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Kết quả và ký hiệu: Hội đồng XSKT miền Bắc'),
            onTap: () => launchUrl(
              Uri.parse('https://xosomb.com.vn/xo-so-truyen-thong'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}
