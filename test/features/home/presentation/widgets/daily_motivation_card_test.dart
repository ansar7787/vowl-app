import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/home/presentation/widgets/daily_motivation_card.dart';

class MockHapticService extends Mock implements HapticService {}

class MockLocaleService extends Mock implements LocaleService {}

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'assets/curriculum/calendar/vowl_calendar.json') {
      return jsonEncode({
        'annual': {
          '11-02': {
            'title': 'Calendar Tip',
            'text': "A day name and a date are different things: 'Monday' is the weekday.",
          }
        }
      });
    }
    return '';
  }

  @override
  Future<ByteData> load(String key) async {
    final str = await loadString(key);
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(str)));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;
  late List<String> navigatedRoutes;

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockHapticService = MockHapticService();
    mockLocaleService = MockLocaleService();
    navigatedRoutes = [];

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));
    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer((inv) {
      final key = inv.positionalArguments.first as String;
      final fallback = inv.namedArguments[#fallback] as String?;
      return fallback ?? key;
    });

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
  });

  Widget createTestWidget({
    Brightness brightness = Brightness.dark,
    double width = 390,
    double height = 844,
    double textScale = 1.0,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: SingleChildScrollView(
              child: DailyMotivationCard(streakCount: 14),
            ),
          ),
        ),
        GoRoute(
          path: AppRouter.libraryRoute,
          builder: (context, state) => const Scaffold(body: Text('LibraryScreen')),
        ),
        GoRoute(
          path: AppRouter.categoryGamesRoute,
          builder: (context, state) => Scaffold(
            body: Text('CategoryGames: ${state.uri.queryParameters['category']}'),
          ),
        ),
      ],
    );

    router.routerDelegate.addListener(() {
      final location = router.routerDelegate.currentConfiguration.uri.toString();
      navigatedRoutes.add(location);
    });

    return DefaultAssetBundle(
      bundle: TestAssetBundle(),
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          textScaler: TextScaler.linear(textScale),
        ),
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp.router(
            theme: ThemeData(
              brightness: brightness,
              scaffoldBackgroundColor:
                  brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white,
            ),
            routerConfig: router,
          ),
        ),
      ),
    );
  }

  group('Piece 9: DailyMotivationCard Editorial Rendering Tests', () {
    testWidgets('renders date, topic pill, quote body, and practice button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(DailyMotivationCard), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
      expect(find.text('Practice Topic'), findsOneWidget);
      expect(find.text('Daily Language Note'), findsOneWidget);
    });

    testWidgets('quote text is left-aligned', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      final quoteFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text && (widget.data ?? '').contains('day name and a date'),
      );
      expect(quoteFinder, findsOneWidget);
      final quoteWidget = tester.widget<Text>(quoteFinder);
      expect(quoteWidget.textAlign, equals(TextAlign.left));
      expect(quoteWidget.softWrap, isTrue);
    });
  });

  group('Piece 9: DailyMotivationCard Navigation Tests', () {
    testWidgets('tapping Practice Topic triggers haptics and navigates', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Practice Topic'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes.isNotEmpty, isTrue);
      verify(() => mockHapticService.selection()).called(1);
    });
  });

  group('Piece 9: DailyMotivationCard Responsiveness & Accessibility', () {
    testWidgets('renders cleanly on 320dp small mobile screen without overflow', (tester) async {
      await tester.pumpWidget(createTestWidget(width: 320, height: 568));
      await tester.pumpAndSettle();

      expect(find.byType(DailyMotivationCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with 1.3x accessibility text zoom', (tester) async {
      await tester.pumpWidget(createTestWidget(textScale: 1.3));
      await tester.pumpAndSettle();

      expect(find.byType(DailyMotivationCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in Light mode', (tester) async {
      await tester.pumpWidget(createTestWidget(brightness: Brightness.light));
      await tester.pumpAndSettle();

      expect(find.byType(DailyMotivationCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

