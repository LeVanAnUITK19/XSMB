import '../models/result_model.dart';

List<Map<String, dynamic>> transformData(
  List<ProvinceResult> provinces,
  String filter,
) {
  const keys = ['DB', 'G1', 'G2', 'G3', 'G4', 'G5', 'G6', 'G7'];
  return keys
      .map(
        (key) => {
          'label': key,
          'values': provinces
              .map(
                (p) => (p.full[key] ?? [])
                    .map((number) {
                      final length = filter == '2'
                          ? 2
                          : filter == '3'
                          ? 3
                          : 0;
                      return length > 0 && number.length >= length
                          ? number.substring(number.length - length)
                          : number;
                    })
                    .join('\n'),
              )
              .toList(),
        },
      )
      .toList();
}
