import 'lottery_check_result.dart';
import 'prize_rule.dart';
import 'tax_calculator.dart';

class LotteryChecker {
  static String normalizeSymbol(String value) {
    final match = RegExp(
      r'^0*([0-9]{1,2})([A-Z]{1,3})$',
    ).firstMatch(value.replaceAll(RegExp(r'\s+'), '').toUpperCase());
    if (match == null) return '';
    final number = int.parse(match[1]!);
    return number >= 1 && number <= 25 ? '$number${match[2]}' : '';
  }

  static DataStatus validateResults(Map<String, List<String>> results) {
    for (final rule in TraditionalPrizeRules.allMainPrizes) {
      final values = results[rule.code];
      if (values == null ||
          values.length != rule.resultCount ||
          values.any(
            (number) => !RegExp(
              '^[0-9]{${rule.matchDigits}}\$',
            ).hasMatch(number.trim()),
          )) {
        return DataStatus.incomplete;
      }
    }
    return DataStatus.complete;
  }

  static LotteryCheckResult check({
    required String ticketNumber,
    required String station,
    required DateTime drawDate,
    required Map<String, List<String>> results,
    String regionKey = 'mien-bac',
    int ticketPrice = 10000,
    DateTime? paymentDate,
    String ticketSymbol = '',
    List<String> specialSymbols = const [],
    int seriesCount = 15,
    int specialPrizeAmount = 500000000,
    int secondaryPrizeAmount = 25000000,
  }) {
    final ticket = ticketNumber.trim();
    var status = DataStatus.complete;
    final winnings = <WinningPrize>[];
    if (regionKey != 'mien-bac') {
      status = DataStatus.unsupportedRegion;
    } else if (ticketPrice != 10000) {
      status = DataStatus.unsupportedTicket;
    } else if (!RegExp(r'^[0-9]{5}$').hasMatch(ticket) ||
        ![15, 20].contains(seriesCount) ||
        specialPrizeAmount <= 0 ||
        secondaryPrizeAmount <= 0) {
      status = DataStatus.invalidTicket;
    } else if (results.isEmpty || station.trim().isEmpty) {
      status = DataStatus.notFound;
    } else {
      status = validateResults(results);
    }
    if (status == DataStatus.complete) {
      for (final rule in TraditionalPrizeRules.allMainPrizes.where(
        (rule) => rule.code != 'DB',
      )) {
        final tail = ticket.substring(5 - rule.matchDigits);
        for (final raw in results[rule.code]!) {
          if (raw.trim() == tail) {
            winnings.add(
              WinningPrize(
                prizeCode: rule.code,
                prizeName: rule.name,
                amount: rule.amount,
                matchedNumber: raw.trim(),
              ),
            );
          }
        }
      }
      final special = results['DB']!.single.trim();
      // Khuyến khích là một hạng riêng; vé trúng nhiều hạng được cộng đủ.
      if (ticket.substring(3) == special.substring(3)) {
        winnings.add(
          WinningPrize(
            prizeCode: 'KK',
            prizeName: 'Giải Khuyến Khích',
            amount: 40000,
            matchedNumber: special,
            note: 'Trùng 2 số cuối giải Đặc Biệt',
          ),
        );
      }
      if (ticket == special) {
        final normalized = normalizeSymbol(ticketSymbol);
        final symbols = specialSymbols.map(normalizeSymbol).toList();
        final expected = seriesCount == 15 ? 6 : 8;
        final letters = symbols
            .map((value) => value.replaceAll(RegExp(r'[0-9]'), ''))
            .toSet();
        if (normalized.isEmpty ||
            symbols.length != expected ||
            symbols.any((value) => value.isEmpty) ||
            symbols.toSet().length != expected ||
            letters.length != 1) {
          status = DataStatus.needsSymbol;
        } else if (int.parse(RegExp(r'^\d+').stringMatch(normalized)!) >
                seriesCount ||
            !normalized.endsWith(letters.single)) {
          status = DataStatus.invalidTicket;
        } else {
          final match = symbols.contains(normalized);
          winnings.add(
            WinningPrize(
              prizeCode: match ? 'DB' : 'DB_PHU',
              prizeName: match ? 'Giải Đặc Biệt' : 'Giải Phụ Đặc Biệt',
              amount: match ? specialPrizeAmount : secondaryPrizeAmount,
              matchedNumber: special,
              note: match
                  ? 'Trùng 5 số và ký hiệu ĐB'
                  : 'Trùng 5 số, khác ký hiệu trúng ĐB',
            ),
          );
        }
      }
    }
    final total = winnings.fold(0, (sum, item) => sum + item.amount);
    final tax = TaxCalculator.calculate(total, paymentDate: paymentDate);
    return LotteryCheckResult(
      ticketNumber: ticket,
      station: station,
      drawDate: drawDate,
      isWinner: winnings.isNotEmpty,
      winnings: List.unmodifiable(winnings),
      grossPrize: total,
      taxableAmount: tax.taxableAmount,
      taxAmount: tax.taxAmount,
      netPrize: tax.netPrize,
      dataStatus: status,
      taxThreshold: tax.threshold,
      paymentDate: tax.paymentDate,
    );
  }
}
