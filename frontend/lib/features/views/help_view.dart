import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_config.dart';

class HelpView extends StatelessWidget {
  const HelpView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hướng dẫn & hỗ trợ')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Xem kết quả',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Chọn đúng ngày trên vé. Miền Bắc có một bảng kết quả chung với 27 số từ Đặc biệt đến Giải Bảy. Dùng nút tải lại để lấy kết quả mới; vuốt trái/phải hoặc nhấn lịch để đổi ngày.',
        ),
        const SizedBox(height: 20),
        const Text(
          'Dò vé 5 chữ số',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Nhập đủ 5 chữ số và giữ nguyên số 0 đầu. Nếu số trùng Đặc biệt, cần ký hiệu vé và chọn đúng bộ 15 hoặc 20 ký hiệu. Nhập đúng mức ĐB/phụ ĐB in trên vé khi khác cơ cấu tham chiếu. Chưa đủ kết quả hoặc ký hiệu thì ứng dụng không kết luận vé thua.',
        ),
        const SizedBox(height: 20),
        const Text(
          'Kết nối máy chủ',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Mở Cấu hình máy chủ trong menu hoặc biểu tượng cài đặt. Nhập URL API của backend bạn sử dụng, rồi lưu. Khi đổi địa chỉ, dữ liệu cũ được xóa khỏi cache trước khi tải kết quả từ máy chủ mới.',
        ),
        const SizedBox(height: 20),
        const Text(
          'Lịch sử và thống kê',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Chỉ lượt dò có đủ dữ liệu mới được lưu. Lịch sử nằm trên thiết bị; có thể xóa từng lượt hoặc toàn bộ trong màn hình lịch sử. Các con số thống kê phản ánh lượt dò đã lưu, không dự đoán kết quả tương lai.',
        ),
        const SizedBox(height: 20),
        if (AppConfig.supportEmail.isNotEmpty)
          FilledButton.icon(
            onPressed: () => launchUrl(
              Uri(
                scheme: 'mailto',
                path: AppConfig.supportEmail,
                queryParameters: {'subject': 'Phản hồi XSMB'},
              ),
            ),
            icon: const Icon(Icons.email_outlined),
            label: const Text('Gửi phản hồi'),
          ),
        ListTile(
          leading: const Icon(Icons.open_in_new),
          title: const Text('Hội đồng XSKT miền Bắc'),
          onTap: () => launchUrl(
            Uri.parse('https://xosomb.com.vn/'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    ),
  );
}
