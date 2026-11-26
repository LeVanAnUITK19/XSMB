import 'package:flutter/material.dart';
import '../../core/constants/api.dart';

class ApiSettingsView extends StatefulWidget {
  const ApiSettingsView({super.key});
  @override
  State<ApiSettingsView> createState() => _ApiSettingsViewState();
}

class _ApiSettingsViewState extends State<ApiSettingsView> {
  final controller = TextEditingController();
  String? error;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    Api.baseUrl()
        .then((value) {
          if (mounted) controller.text = value;
        })
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await Api.saveBase(controller.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cấu hình máy chủ')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Image.asset('assets/images/xsmb_logo.png', height: 150),
        const SizedBox(height: 20),
        const Text(
          'Nhập địa chỉ backend XSMB sau khi bạn deploy. Có thể đổi địa chỉ tại đây mà không cần cài lại ứng dụng.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Địa chỉ API',
            hintText: 'https://ten-backend-cua-ban/api/',
            errorText: error,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(saving ? 'Đang lưu...' : 'Lưu địa chỉ'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Chạy thử Android emulator: http://10.0.2.2:3000/api/\nKhi deploy sử dụng HTTPS.',
        ),
      ],
    ),
  );
}
