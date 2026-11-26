import 'dart:convert';
import '../models/result_model.dart';
import '../constants/api.dart';
import '../constants/regions.dart';

class ResultService {
  final RegionConfig region;

  ResultService(this.region);

  static List<LotteryResult> parseResults(String body, String regionKey) {
    final decoded = jsonDecode(body);
    final data = decoded is List
        ? decoded
        : decoded is Map
        ? decoded['data']
        : null;
    if (data is! List) {
      throw const FormatException('Dữ liệu kết quả không hợp lệ');
    }
    return data
        .map(
          (item) =>
              LotteryResult.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .where((item) => item.region == regionKey)
        .toList();
  }

  Future<List<LotteryResult>> getAll() async {
    final res = await Api.safeGet('results', region);
    if (res.statusCode == 200) {
      return parseResults(res.body, region.regionKey);
    }
    throw Exception('API error: ${res.statusCode}');
  }

  Future<LotteryResult> getOne({required String date}) async {
    final endpoint = 'results/filter?date=$date&region=${region.regionKey}';
    final res = await Api.safeGet(endpoint, region);
    if (res.statusCode == 200) {
      final data = parseResults(res.body, region.regionKey)
          .where((item) => item.date.toIso8601String().substring(0, 10) == date)
          .toList();
      if (data.isEmpty) throw Exception('No data found');
      final map = data.firstWhere(
        (e) => e.provinces.isNotEmpty,
        orElse: () => data.first,
      );
      return map;
    }
    throw Exception('API error: ${res.statusCode}');
  }
}
