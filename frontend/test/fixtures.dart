import 'package:xsmb/core/constants/regions.dart';
import 'package:xsmb/core/models/result_model.dart';
import 'package:xsmb/core/services/result_service.dart';

Map<String, List<String>> numbers() => {
  'DB': ['09621'],
  'G1': ['94511'],
  'G2': ['45861', '12148'],
  'G3': ['71783', '78735', '51470', '65528', '40137', '81658'],
  'G4': ['4313', '7769', '7940', '7024'],
  'G5': ['2664', '3366', '7276', '1676', '5651', '4129'],
  'G6': ['150', '831', '685'],
  'G7': ['82', '54', '95', '34'],
};
const symbols = ['4LU', '11LU', '12LU', '3LU', '5LU', '7LU'];
LotteryResult fixture({bool complete = true}) => LotteryResult(
  id: 'fixture',
  date: DateTime(2026, 11, 26),
  region: 'mien-bac',
  provinces: [
    ProvinceResult(
      province: 'Miền Bắc',
      full: complete ? numbers() : (numbers()..['G3'] = []),
      specialSymbols: symbols,
    ),
  ],
);

class FakeService extends ResultService {
  final LotteryResult value;
  bool empty = false;
  int calls = 0;
  FakeService({bool complete = true})
    : value = fixture(complete: complete),
      super(Regions.mienBac);
  @override
  Future<List<LotteryResult>> getAll() async {
    calls++;
    return empty ? [] : [value];
  }

  @override
  Future<LotteryResult> getOne({required String date}) async => value;
}
