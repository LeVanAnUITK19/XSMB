import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsmb/core/constants/regions.dart';
import 'package:xsmb/features/viewModels/home_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb/core/constants/api.dart';
import 'package:xsmb/core/services/result_service.dart';
import 'package:xsmb/core/utils/transform_data.dart';
import 'fixtures.dart';

void main() {
  test('URL backend được chuẩn hóa', () {
    expect(
      Api.normalizeBase('https://example.com'),
      'https://example.com/api/',
    );
    expect(
      Api.normalizeBase('https://example.com/api/results'),
      'https://example.com/api/',
    );
    expect(
      () => Api.normalizeBase('https://user:pass@example.com/api'),
      throwsFormatException,
    );
  });
  test('Đọc payload danh sách/phân trang và ký hiệu không mất số 0', () {
    for (final body in [
      jsonEncode([fixture().toJson()]),
      jsonEncode({
        'data': [fixture().toJson()],
      }),
    ]) {
      final data = ResultService.parseResults(body, 'mien-bac').single;
      expect(data.provinces.single.full['DB'], ['09621']);
      expect(data.provinces.single.specialSymbols, symbols);
    }
  });
  test('Bảng miền Bắc không có G8 và hiển thị ĐB trước', () {
    final rows = transformData(fixture().provinces, 'full');
    expect(rows.first['label'], 'DB');
    expect(rows.length, 8);
    expect(rows.any((row) => row['label'] == 'G8'), false);
  });
  test('API trả rỗng phải bỏ kết quả cache cũ', () async {
    SharedPreferences.setMockInitialValues({});
    final service = FakeService();
    final vm = ResultViewModel(Regions.mienBac, service: service);
    await vm.load();
    expect(vm.result, isNotNull);
    service.empty = true;
    await vm.load();
    expect(vm.result, isNull);
    vm.dispose();
  });
}
