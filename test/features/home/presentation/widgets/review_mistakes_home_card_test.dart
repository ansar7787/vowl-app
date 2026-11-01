import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/home/presentation/widgets/review_mistakes_home_card.dart';

class MockHapticService extends Mock implements HapticService {}

class MockLocaleService extends Mock implements LocaleService {}

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
      final args = inv.namedArguments[#args] as List<dynamic>?;

      String text = fallback ?? key;
      if (args != null && args.isNotEmpty) {
        text = text.replaceAll('{0}', args[0].toString());
      }
      return text;
    });

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    initLocaleServiceReference(mockLocaleService);
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
  });

  Widget createSubject({
    required UserEntity user,
    ThemeMode themeMode = ThemeMode.dark,
    double width = 390,
    double height = 844,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: SingleChildScrollView(
              child: ReviewMistakesHomeCard(user: user),
            ),
          ),
        ),
        GoRoute(
          path: '/review-mistakes',
          builder: (context, _) {
            navigatedRoutes.add('/review-mistakes');
            return const Scaffold(body: Text('Review Mistakes Screen'));
          },
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: Size(width, height),
      builder: (context, _) => MaterialApp.router(
        routerConfig: router,
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
      ),
    );
  }

  Future<void> pumpSubject(
    WidgetTester tester, {
    required UserEntity user,
    ThemeMode themeMode = ThemeMode.dark,
    double width = 390,
    double height = 844,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(createSubject(
      user: user,
      themeMode: themeMode,
      width: width,
      height: height,
    ));
    await tester.pumpAndSettle();
  }

  const localUser = UserEntity(
    id: 'local',
    email: 'guest@vowl.app',
    displayName: 'Guest Learner',
  );

  group('ReviewMistakesHomeCard - Visibility & Rendering', () {
    testWidgets('renders SizedBox.shrink when error count is 0', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': <String>[],
      });

      await pumpSubject(tester, user: localUser);

      expect(find.byType(ReviewMistakesHomeCard), findsOneWidget);
      expect(find.text('Review & Master'), findsNothing);
    });

    testWidgets('renders card with singular subtitle when count is 1', (tester) async {
      final mistake = jsonEncode({
        'id': 'entry_1',
        'gameType': 'syllableStress',
        'question': 'Identify stress in banana',
        'userAnswer': 'ba-NA-na',
        'correctAnswer': 'ba-NA-na',
        'level': 1,
      });
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': [mistake],
      });

      await pumpSubject(tester, user: localUser);

      expect(find.text('Review & Master'), findsOneWidget);
      expect(find.text('Master 1 past challenge'), findsOneWidget);
      expect(find.byIcon(Icons.crisis_alert_rounded), findsOneWidget);
    });

    testWidgets('renders card with plural count when count > 1', (tester) async {
      final mistake1 = jsonEncode({
        'id': 'entry_1',
        'gameType': 'syllableStress',
        'question': 'Q1',
        'userAnswer': 'A',
        'correctAnswer': 'B',
        'level': 1,
      });
      final mistake2 = jsonEncode({
        'id': 'entry_2',
        'gameType': 'syllableStress',
        'question': 'Q2',
        'userAnswer': 'X',
        'correctAnswer': 'Y',
        'level': 2,
      });
      final mistake3 = jsonEncode({
        'id': 'entry_3',
        'gameType': 'wordScramble',
        'question': 'Q3',
        'userAnswer': 'P',
        'correctAnswer': 'Q',
        'level': 1,
      });

      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': [mistake1, mistake2, mistake3],
      });

      await pumpSubject(tester, user: localUser);

      expect(find.text('Review & Master'), findsOneWidget);
      expect(find.text('Master 3 past challenges'), findsOneWidget);
      expect(find.byIcon(Icons.crisis_alert_rounded), findsOneWidget);
    });
  });

  group('ReviewMistakesHomeCard - Interaction & Navigation', () {
    testWidgets('tapping card triggers haptics and navigates to /review-mistakes', (tester) async {
      final mistake = jsonEncode({
        'id': 'entry_1',
        'gameType': 'syllableStress',
        'question': 'Identify stress',
        'userAnswer': 'wrong',
        'correctAnswer': 'right',
        'level': 1,
      });
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': [mistake],
      });

      await pumpSubject(tester, user: localUser);

      await tester.tap(find.text('Review & Master'));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);
      expect(navigatedRoutes, contains('/review-mistakes'));
    });
  });

  group('ReviewMistakesHomeCard - Screen Size & Theme Resilience', () {
    testWidgets('renders cleanly on compact 320dp screen without overflow', (tester) async {
      final mistake = jsonEncode({
        'id': 'entry_1',
        'gameType': 'syllableStress',
        'question': 'Identify stress',
        'userAnswer': 'wrong',
        'correctAnswer': 'right',
        'level': 1,
      });
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': [mistake],
      });

      await pumpSubject(tester, user: localUser, width: 320, height: 600);

      expect(tester.takeException(), isNull);
      expect(find.text('Review & Master'), findsOneWidget);
      expect(find.text('Master 1 past challenge'), findsOneWidget);
    });

    testWidgets('renders cleanly in light mode', (tester) async {
      final mistake = jsonEncode({
        'id': 'entry_1',
        'gameType': 'syllableStress',
        'question': 'Identify stress',
        'userAnswer': 'wrong',
        'correctAnswer': 'right',
        'level': 1,
      });
      SharedPreferences.setMockInitialValues({
        'vowl_local_error_journal': [mistake],
      });

      await pumpSubject(tester, user: localUser, themeMode: ThemeMode.light);

      expect(tester.takeException(), isNull);
      expect(find.text('Review & Master'), findsOneWidget);
    });
  });
}

