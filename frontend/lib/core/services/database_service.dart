import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_history_model.dart';

/// Lưu lịch sử trên thiết bị, dùng được cả Android, iOS và web.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();
  static const _key = 'xsmb_ticket_history_v1';
  Future<void>? _pendingWrite;

  Future<List<TicketHistory>> getAllTicketHistories({String? regionKey}) async {
    final pending = _pendingWrite;
    if (pending != null) await pending;
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_key) ?? [];
    final result = <TicketHistory>[];
    for (final entry in entries) {
      try {
        final history = TicketHistory.fromMap(
          Map<String, dynamic>.from(jsonDecode(entry) as Map),
        );
        if (regionKey == null || history.regionKey == regionKey) {
          result.add(history);
        }
      } on FormatException {
        // Bỏ riêng bản ghi hỏng, vẫn đọc được các vé còn lại.
      } on TypeError {
        // Bản ghi không đúng schema không được tính vào thống kê.
      }
    }
    result.sort((a, b) => b.checkedAt.compareTo(a.checkedAt));
    return result;
  }

  Future<int> _write(int Function(List<String>) update) {
    final operation = (_pendingWrite ?? Future<void>.value()).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final entries = List<String>.from(prefs.getStringList(_key) ?? []);
      final result = update(entries);
      if (!await prefs.setStringList(_key, entries)) {
        throw StateError('Không lưu được lịch sử dò vé');
      }
      return result;
    });
    final barrier = operation.then<void>((_) {}, onError: (Object _) {});
    _pendingWrite = barrier;
    barrier.then((_) {
      if (identical(_pendingWrite, barrier)) _pendingWrite = null;
    });
    return operation;
  }

  Future<int> insertTicketHistory(TicketHistory history) => _write((entries) {
    final id = DateTime.now().microsecondsSinceEpoch;
    entries.add(jsonEncode({...history.toMap(), 'id': id}));
    return id;
  });

  Future<int> deleteTicketHistory(int id) => _write((entries) {
    final before = entries.length;
    entries.removeWhere((entry) => (jsonDecode(entry) as Map)['id'] == id);
    return before - entries.length;
  });

  Future<int> clearAllTicketHistories({String? regionKey}) => _write((entries) {
    final before = entries.length;
    if (regionKey == null) {
      entries.clear();
    } else {
      entries.removeWhere(
        (entry) => (jsonDecode(entry) as Map)['regionKey'] == regionKey,
      );
    }
    return before - entries.length;
  });

  Future<TicketStats> getStats({String? regionKey}) async {
    final all = await getAllTicketHistories(regionKey: regionKey);
    final stations = <String, List<TicketHistory>>{};
    for (final history in all) {
      stations.putIfAbsent(history.station, () => []).add(history);
    }
    final byStation =
        stations.entries
            .map(
              (entry) => StationStat(
                station: entry.key,
                total: entry.value.length,
                wins: entry.value.where((history) => history.isWin).length,
              ),
            )
            .toList()
          ..sort((a, b) => b.total.compareTo(a.total));
    return TicketStats(
      total: all.length,
      totalWins: all.where((history) => history.isWin).length,
      byStation: byStation,
    );
  }
}

class TicketStats {
  final int total;
  final int totalWins;
  final List<StationStat> byStation;
  const TicketStats({
    required this.total,
    required this.totalWins,
    required this.byStation,
  });
  int get totalLosses => total - totalWins;
  double get winRate => total == 0 ? 0 : totalWins / total;
}

class StationStat {
  final String station;
  final int total;
  final int wins;
  const StationStat({
    required this.station,
    required this.total,
    required this.wins,
  });
  int get losses => total - wins;
}
