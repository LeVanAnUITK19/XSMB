import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/result_model.dart';
import '../../core/services/result_service.dart';
import '../../core/services/cache_service.dart';
import '../../core/constants/regions.dart';

class ResultViewModel extends ChangeNotifier {
  final RegionConfig region;
  final ResultService _service;
  final Map<String, LotteryResult> _cache = {};
  LotteryResult? result;
  bool isLoading = true;
  bool isRefreshing = false;
  bool notFound = false;
  bool _disposed = false;
  bool _hasSelectedDate = false;
  String? error;
  DateTime currentDate = DateTime.now();
  ResultViewModel(this.region, {ResultService? service})
    : _service = service ?? ResultService(region);
  String get _cacheKey => 'results_all_${region.regionKey}';
  static String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (isRefreshing) return;
    error = null;
    isRefreshing = true;
    if (_cache.isEmpty) {
      try {
        final saved = await CacheService.get(
          _cacheKey,
          maxAge: const Duration(hours: 12),
        );
        if (saved != null) {
          _store(ResultService.parseResults(saved, region.regionKey));
        }
      } catch (_) {
        /* Cache hỏng vẫn được thay bằng dữ liệu từ API. */
      }
    }
    isLoading = result == null;
    _notify();
    try {
      final all = await _service.getAll();
      if (all.isEmpty) {
        _cache.clear();
        result = null;
      }
      _store(all);
      await CacheService.save(
        _cacheKey,
        jsonEncode(all.map((item) => item.toJson()).toList()),
      );
    } catch (exception) {
      error = 'Không thể tải dữ liệu mới: $exception';
    } finally {
      isLoading = false;
      isRefreshing = false;
      _notify();
    }
  }

  void _store(List<LotteryResult> all) {
    for (final item in all) {
      if (item.region == region.regionKey && item.provinces.isNotEmpty) {
        _cache[dateKey(item.date)] = item;
      }
    }
    if (!_hasSelectedDate) currentDate = DateTime.now();
    result = _cache[dateKey(currentDate)];
    if (result == null && _cache.isNotEmpty) {
      final latest = (_cache.keys.toList()..sort()).last;
      currentDate = DateTime.parse(latest);
      result = _cache[latest];
    }
  }

  LotteryResult? getCache(String key) => _cache[key];
  Future<LotteryResult?> fetchByDate(
    DateTime date, {
    bool refresh = false,
  }) async {
    final key = dateKey(date);
    if (!refresh && _cache.containsKey(key)) return _cache[key];
    final item = await _service.getOne(date: key);
    if (item.region != region.regionKey || dateKey(item.date) != key) {
      throw const FormatException('Kết quả không khớp miền hoặc ngày trên vé');
    }
    _cache[key] = item;
    return item;
  }

  Future<void> loadByDate(DateTime date) async {
    try {
      final item = await fetchByDate(date);
      if (_disposed) return;
      currentDate = date;
      _hasSelectedDate = true;
      result = item;
      notFound = item == null;
      error = null;
    } catch (exception) {
      notFound = true;
      error = 'Không tải được kết quả ngày đã chọn: $exception';
    }
    _notify();
  }

  Future<void> resetData() async {
    _cache.clear();
    result = null;
    _hasSelectedDate = false;
    currentDate = DateTime.now();
    await CacheService.clear(_cacheKey);
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
