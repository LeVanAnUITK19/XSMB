import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb/core/lottery/lottery_checker.dart';
import 'package:xsmb/core/lottery/lottery_check_result.dart';
import 'package:xsmb/core/lottery/tax_calculator.dart';
import 'fixtures.dart';

LotteryCheckResult check(
  String ticket, {
  String code = '',
  List<String> winning = symbols,
  Map<String, List<String>>? results,
  int series = 15,
  int specialAmount = 500000000,
}) => LotteryChecker.check(
  ticketNumber: ticket,
  station: 'Miền Bắc',
  drawDate: DateTime(2026, 11, 26),
  results: results ?? numbers(),
  ticketSymbol: code,
  specialSymbols: winning,
  seriesCount: series,
  specialPrizeAmount: specialAmount,
  paymentDate: DateTime(2026, 11, 26),
);
void main() {
  test('Vé mệnh giá khác không suy ra tiền thưởng từ cơ cấu 10.000đ', () {
    final result = LotteryChecker.check(
      ticketNumber: '94511',
      station: 'Miền Bắc',
      drawDate: DateTime(2026, 11, 26),
      results: numbers(),
      ticketPrice: 20000,
    );
    expect(result.dataStatus, DataStatus.unsupportedTicket);
    expect(result.grossPrize, 0);
  });
  const amounts = {
    'G1': 10000000,
    'G2': 5000000,
    'G3': 1000000,
    'G4': 400000,
    'G5': 200000,
    'G6': 100000,
    'G7': 40000,
  };
  for (final entry in numbers().entries.where((entry) => entry.key != 'DB')) {
    for (final value in entry.value) {
      test('${entry.key} $value đúng số chữ số và mức thưởng', () {
        final result = check(value.padLeft(5, '9'));
        expect(
          result.winnings
              .where(
                (prize) =>
                    prize.prizeCode == entry.key &&
                    prize.matchedNumber == value,
              )
              .single
              .amount,
          amounts[entry.key],
        );
      });
    }
  }
  for (var i = 1; i <= 15; i++) {
    test('Bộ 15 ký hiệu: phân biệt ký hiệu $i LU', () {
      final code = '${i}LU';
      final result = check('09621', code: code);
      expect(result.dataStatus, DataStatus.complete);
      expect(
        result.winnings.any((prize) => prize.prizeCode == 'DB'),
        symbols.contains(code),
      );
      expect(
        result.winnings.any((prize) => prize.prizeCode == 'DB_PHU'),
        !symbols.contains(code),
      );
      expect(
        result.winnings.where((prize) => prize.prizeCode == 'KK').single.amount,
        40000,
      );
      expect(result.grossPrize, symbols.contains(code) ? 500040000 : 25040000);
    });
  }
  test('Giữ số 0 đầu và chuẩn hóa ký hiệu 04 lu', () {
    final result = check('09621', code: '04 lu');
    expect(result.ticketNumber, '09621');
    expect(result.grossPrize, 500040000);
    expect(result.taxAmount, 48004000);
  });
  test('Cơ cấu khác trên vé dùng đúng mức ĐB người dùng nhập', () {
    expect(
      check('09621', code: '4LU', specialAmount: 1000000000).grossPrize,
      1000040000,
    );
  });
  test(
    'Thiếu ký hiệu vé không được kết luận phụ ĐB',
    () => expect(check('09621').dataStatus, DataStatus.needsSymbol),
  );
  test(
    'Thiếu danh sách công bố không kết luận phụ ĐB',
    () => expect(
      check('09621', code: '1LU', winning: []).dataStatus,
      DataStatus.needsSymbol,
    ),
  );
  test(
    'Sai chữ ký hiệu kỳ quay phải kiểm tra lại vé/ngày',
    () => expect(
      check('09621', code: '4XX').dataStatus,
      DataStatus.invalidTicket,
    ),
  );
  test(
    'Ký hiệu vượt bộ 15 không hợp lệ',
    () => expect(
      check('09621', code: '20LU').dataStatus,
      DataStatus.invalidTicket,
    ),
  );
  test(
    'Bộ 20 không kết luận khi chỉ có 6 ký hiệu',
    () => expect(
      check('09621', code: '20LU', series: 20).dataStatus,
      DataStatus.needsSymbol,
    ),
  );
  test('Bộ 20 với 8 ký hiệu công bố: số khác được phụ ĐB', () {
    final codes = List.generate(8, (i) => '${i + 1}LU');
    final result = check('09621', code: '20LU', winning: codes, series: 20);
    expect(result.winnings.any((prize) => prize.prizeCode == 'DB_PHU'), true);
  });
  test('Khuyến khích 2 số cuối ĐB không áp quy tắc sai một số miền Nam', () {
    final result = check('45621');
    expect(result.winnings.any((prize) => prize.prizeCode == 'KK'), true);
    expect(result.winnings.any((prize) => prize.prizeCode == 'DB_PHU'), false);
  });
  test('Đúng 4 số cuối ĐB không phải phụ ĐB miền Nam', () {
    final result = check('19621');
    expect(result.winnings.any((prize) => prize.prizeCode == 'DB_PHU'), false);
  });
  test('Trúng nhiều giải, kể cả các lần quay trùng nhau, được cộng đủ', () {
    final values = numbers()
      ..['G1'] = ['94511']
      ..['G2'] = ['94511', '94511']
      ..['G7'] = ['11', '11', '95', '34'];
    final result = check('94511', results: values);
    expect(result.grossPrize, 20080000);
    expect(result.taxAmount, 8000);
  });
  for (final key in numbers().keys) {
    test(
      'Chưa đủ kết quả $key không thể kết luận vé thua',
      () => expect(
        check('12345', results: numbers()..[key] = []).dataStatus,
        DataStatus.incomplete,
      ),
    );
  }
  for (final ticket in ['123456', '1234', '12a45', '１２３４５']) {
    test(
      'Vé không hợp lệ $ticket',
      () => expect(check(ticket).dataStatus, DataStatus.invalidTicket),
    );
  }
  test(
    'Dữ liệu giả có đủ ô vẫn không hợp lệ',
    () => expect(
      check('12345', results: numbers()..['DB'] = ['Chờ']).dataStatus,
      DataStatus.incomplete,
    ),
  );
  test('Không trúng với dữ liệu đầy đủ', () {
    final result = check('00000');
    expect(result.dataStatus, DataStatus.complete);
    expect(result.isWinner, false);
  });
  test('Thuế áp theo ngày nhận thưởng', () {
    expect(
      TaxCalculator.calculate(
        25000000,
        paymentDate: DateTime(2026, 6, 30),
      ).taxAmount,
      1500000,
    );
    expect(
      TaxCalculator.calculate(
        25000000,
        paymentDate: DateTime(2026, 7, 1),
      ).taxAmount,
      500000,
    );
  });
}
