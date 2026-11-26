/// Cơ cấu tham chiếu vé 10.000đ của XSKT Quảng Ninh.
/// https://www.xosoquangninh.com.vn/xskt/loai-hinh-xo-so/xo-so-truyen-thong
/// Kiểm chứng 26/11/2026. ĐB/phụ ĐB phải đối chiếu cơ cấu in trên vé.
class PrizeRule {
  final String code, name, condition;
  final int amount, matchDigits, resultCount, winnersPerSeries;
  const PrizeRule(
    this.code,
    this.name,
    this.amount,
    this.matchDigits,
    this.resultCount,
  ) : condition = 'Trùng đúng thứ tự các chữ số cuối',
      winnersPerSeries = resultCount;
}

class TraditionalPrizeRules {
  static const ruleVersion = 'XSMB-2026.11';
  static const ruleLastVerifiedAt = '2026-11-26';
  static const specialPrize = PrizeRule('DB', 'Giải Đặc Biệt', 500000000, 5, 1);
  static const firstPrize = PrizeRule('G1', 'Giải Nhất', 10000000, 5, 1);
  static const secondPrize = PrizeRule('G2', 'Giải Nhì', 5000000, 5, 2);
  static const thirdPrize = PrizeRule('G3', 'Giải Ba', 1000000, 5, 6);
  static const fourthPrize = PrizeRule('G4', 'Giải Tư', 400000, 4, 4);
  static const fifthPrize = PrizeRule('G5', 'Giải Năm', 200000, 4, 6);
  static const sixthPrize = PrizeRule('G6', 'Giải Sáu', 100000, 3, 3);
  static const seventhPrize = PrizeRule('G7', 'Giải Bảy', 40000, 2, 4);
  static const allMainPrizes = [
    specialPrize,
    firstPrize,
    secondPrize,
    thirdPrize,
    fourthPrize,
    fifthPrize,
    sixthPrize,
    seventhPrize,
  ];
  static const minimumResultCount = 27;
  static const specialSecondaryPrize = (
    code: 'DB_PHU',
    name: 'Giải Phụ Đặc Biệt',
    amount: 25000000,
    count: 9,
    condition:
        'Trùng 5 chữ số ĐB, ký hiệu hợp lệ nhưng không nằm trong danh sách trúng ĐB',
  );
  static const encouragementPrize = (
    code: 'KK',
    name: 'Giải Khuyến Khích',
    amount: 40000,
    count: 15000,
    condition: 'Trùng 2 số cuối giải ĐB',
  );
}
