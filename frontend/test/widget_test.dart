import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsmb/core/constants/regions.dart';
import 'package:xsmb/core/constants/api.dart';
import 'package:xsmb/core/services/database_service.dart';
import 'package:xsmb/features/viewModels/home_viewmodel.dart';
import 'package:xsmb/features/views/home_view.dart';
import 'package:xsmb/widgets/auto_check.dart';
import 'fixtures.dart';

Widget host(Widget child) => MaterialApp(
  locale: const Locale('vi', 'VN'),
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  supportedLocales: const [Locale('vi', 'VN')],
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF01101)),
    useMaterial3: true,
  ),
  home: child,
);
Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_QA')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('qa')),
  );
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage('assets/images/xsmb_logo.png'),
      tester.element(find.byKey(const ValueKey('qa'))),
    );
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('../.cache/qa/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN', null);
    if (const bool.fromEnvironment('CAPTURE_QA')) {
      final sdk = Platform.environment['FLUTTER_ROOT'];
      if (sdk != null) {
        for (final entry in {
          'Roboto':
              'dart-sdk/bin/resources/devtools/assets/fonts/Roboto/Roboto-Regular.ttf',
          'MaterialIcons': 'artifacts/material_fonts/MaterialIcons-Regular.otf',
        }.entries) {
          final file = File('$sdk/bin/cache/${entry.value}');
          if (file.existsSync()) {
            final loader = FontLoader(entry.key)
              ..addFont(file.readAsBytes().then(ByteData.sublistView));
            await loader.load();
          }
        }
      }
    }
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  void size(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'Lần đầu mở hiển thị logo và cấu hình backend, không gọi URL giả',
    (tester) async {
      size(tester);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('qa'),
          child: host(const HomePageView()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chào mừng đến với XSMB'), findsOneWidget);
      expect(find.text('Cấu hình máy chủ'), findsOneWidget);
      await capture(tester, 'welcome');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Bảng miền Bắc có 27 kết quả và danh sách ký hiệu, menu và logo mới',
    (tester) async {
      size(tester);
      final vm = ResultViewModel(Regions.mienBac, service: FakeService());
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('qa'),
          child: host(HomePageView(viewModel: vm)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('09621'), findsOneWidget);
      expect(find.textContaining('4LU'), findsWidgets);
      expect(find.text('G8'), findsNothing);
      await capture(tester, 'results');
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('Lịch sử dò vé'), findsOneWidget);
      expect(find.text('Phiên bản 1.0.0'), findsOneWidget);
      await capture(tester, 'menu');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
  for (final complete in [true, false]) {
    testWidgets(
      complete
          ? 'Dò đúng 5 số, ký hiệu ĐB và lưu lịch sử'
          : 'Thiếu kết quả không ghi vé thua',
      (tester) async {
        size(tester);
        final vm = ResultViewModel(
          Regions.mienBac,
          service: FakeService(complete: complete),
        );
        await vm.load();
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('qa'),
            child: host(
              Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showCheckTicketDialog(context, vm),
                    child: const Text('Mở dò vé'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Mở dò vé'));
        await tester.pumpAndSettle();
        for (var i = 0; i < 5; i++) {
          await tester.enterText(find.byType(TextField).at(i), '09621'[i]);
        }
        await tester.enterText(
          find.widgetWithText(TextField, 'Ký hiệu vé (ví dụ 4LU)'),
          '4LU',
        );
        await tester.ensureVisible(find.text('Dò Vé'));
        await tester.tap(find.text('Dò Vé'));
        await tester.pumpAndSettle();
        final history = await DatabaseService.instance.getAllTicketHistories();
        if (complete) {
          expect(find.text('Giải Đặc Biệt'), findsOneWidget);
          expect(history.single.ticketNumber, '09621');
          expect(history.single.ticketSymbol, '4LU');
          expect(history.single.grossPrize, 500040000);
          await capture(tester, 'winning');
        } else {
          expect(find.text('Chưa thể dò vé'), findsOneWidget);
          expect(history, isEmpty);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        vm.dispose();
      },
    );
  }
  testWidgets(
    'Trùng số ĐB nhưng thiếu ký hiệu: yêu cầu bổ sung, không lưu vé thua',
    (tester) async {
      size(tester);
      final vm = ResultViewModel(Regions.mienBac, service: FakeService());
      await vm.load();
      await tester.pumpWidget(
        host(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showCheckTicketDialog(context, vm),
                child: const Text('Mở dò vé'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở dò vé'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        await tester.enterText(find.byType(TextField).at(i), '09621'[i]);
      }
      await tester.ensureVisible(find.text('Dò Vé'));
      await tester.tap(find.text('Dò Vé'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cần nhập ký hiệu vé'), findsOneWidget);
      expect(await DatabaseService.instance.getAllTicketHistories(), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      vm.dispose();
    },
  );
  testWidgets('Đổi API từ menu: lưu địa chỉ rồi tải lại kết quả', (
    tester,
  ) async {
    size(tester);
    final service = FakeService();
    final vm = ResultViewModel(Regions.mienBac, service: service);
    await tester.pumpWidget(host(HomePageView(viewModel: vm)));
    await tester.pumpAndSettle();
    expect(service.calls, 1);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cấu hình máy chủ'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Địa chỉ API'),
      'https://api.example.com/api/',
    );
    await tester.tap(find.text('Lưu địa chỉ'));
    await tester.pumpAndSettle();
    expect(await Api.baseUrl(), 'https://api.example.com/api/');
    expect(service.calls, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
}
