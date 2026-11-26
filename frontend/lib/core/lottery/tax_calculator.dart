/// Điều 15 Luật 109/2025/QH15. Thuế theo ngày trả thưởng, không theo ngày quay.
class TaxCalculator {
  TaxCalculator._();
  static const int taxThreshold = 20000000;
  static const double taxRate = 0.10;
  static TaxResult calculate(int grossPrize, {DateTime? paymentDate}) {
    if (grossPrize < 0) throw ArgumentError.value(grossPrize, 'grossPrize');
    final paidAt = paymentDate ?? DateTime.now();
    final day = DateTime(paidAt.year, paidAt.month, paidAt.day);
    final threshold = day.isBefore(DateTime(2026, 7, 1))
        ? 10000000
        : taxThreshold;
    final taxable = grossPrize > threshold ? grossPrize - threshold : 0;
    final tax = (taxable * taxRate).round();
    return TaxResult(
      grossPrize: grossPrize,
      taxableAmount: taxable,
      taxAmount: tax,
      netPrize: grossPrize - tax,
      threshold: threshold,
      paymentDate: day,
    );
  }
}

class TaxResult {
  final int grossPrize, taxableAmount, taxAmount, netPrize, threshold;
  final DateTime paymentDate;
  const TaxResult({
    required this.grossPrize,
    required this.taxableAmount,
    required this.taxAmount,
    required this.netPrize,
    required this.threshold,
    required this.paymentDate,
  });
}
