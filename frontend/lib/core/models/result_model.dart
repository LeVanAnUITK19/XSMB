class ProvinceResult {
  final String province;
  final Map<String, List<String>> full;
  final List<String> specialSymbols;

  ProvinceResult({
    required this.province,
    required this.full,
    this.specialSymbols = const [],
  });

  factory ProvinceResult.fromJson(Map<String, dynamic> json) {
    final fullMap = (json['full'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, List<String>.from(value as List)),
    );
    return ProvinceResult(
      province: json['province'] as String,
      full: fullMap,
      specialSymbols: List<String>.from(json['specialSymbols'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'province': province,
    'full': full,
    'specialSymbols': specialSymbols,
  };
}

class LotteryResult {
  final String id;
  final DateTime date;
  final String region;
  final List<ProvinceResult> provinces;

  LotteryResult({
    required this.id,
    required this.date,
    required this.region,
    required this.provinces,
  });

  factory LotteryResult.fromJson(Map<String, dynamic> json) {
    return LotteryResult(
      id: json['_id'] as String,
      date: DateTime.parse(json['date'] as String),
      region: json['region'] as String,
      provinces: (json['provinces'] as List)
          .map((p) => ProvinceResult.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'date': date.toIso8601String(),
    'region': region,
    'provinces': provinces.map((province) => province.toJson()).toList(),
  };
}
