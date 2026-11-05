import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/home/presentation/widgets/discovery_deck.dart';

class MockHapticService extends Mock implements HapticService {}

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;
  late List<String> launchedQuests;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    VowlMotion.lowAnimationModeOverride.value = true;
    mockHapticService = MockHapticService();
    mockLocaleService = MockLocaleService();
    launchedQuests = [];

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
        for (int i = 0; i < args.length; i++) {
          text = text.replaceAll('{$i}', args[i].toString());
          text = text.replaceAll('{}', args[i].toString());
        }
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
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
  });

  final testUser = UserEntity(
    id: 'user_discovery_001',
    email: 'learner@vowl.com',
    displayName: 'Aria',
    currentStreak: 12,
    coins: 350,
  );

  Widget createTestWidget({
    Brightness brightness = Brightness.dark,
    double width = 390,
    double height = 844,
    double textScale = 1.0,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: Size(width, height),
        textScaler: TextScaler.linear(textScale),
      ),
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          theme: ThemeData(
            brightness: brightness,
            scaffoldBackgroundColor:
                brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DiscoveryDeck(
                user: testUser,
                onLaunchQuest: (id) => launchedQuests.add(id),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Piece 9: DiscoveryDeck Architecture & Rendering Tests', () {
    testWidgets('renders Flagship Hero Card: Smart Focus (Adaptive AI)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Smart Focus'), findsOneWidget);
      expect(find.text('ADAPTIVE AI'), findsOneWidget);
      expect(find.text('Targeted practice for your weakest skills'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);
    });

    testWidgets('renders 3-Cell Superpower Row: Daily Workout, Rapid Recall, Sentence Lab', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Daily Workout'), findsOneWidget);
      expect(find.text('2 Steps'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_motion_rounded), findsOneWidget);

      expect(find.text('Rapid Recall'), findsOneWidget);
      expect(find.text('Speed Drill'), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);

      expect(find.text('Sentence Lab'), findsOneWidget);
      expect(find.text('Syntax'), findsOneWidget);
      expect(find.byIcon(Icons.architecture_rounded), findsOneWidget);
    });
  });

  group('Piece 9: DiscoveryDeck Interaction & Navigation Tests', () {
    testWidgets('tapping Smart Focus hero card launches smart_focus and triggers haptic', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Smart Focus'));
      await tester.pumpAndSettle();

      expect(launchedQuests, ['smart_focus']);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('tapping Daily Workout subcell launches daily_workout and triggers haptic', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Daily Workout'));
      await tester.pumpAndSettle();

      expect(launchedQuests, ['daily_workout']);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('tapping Rapid Recall subcell launches rapid_recall and triggers haptic', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rapid Recall'));
      await tester.pumpAndSettle();

      expect(launchedQuests, ['rapid_recall']);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('tapping Sentence Lab subcell launches sentence_lab and triggers haptic', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sentence Lab'));
      await tester.pumpAndSettle();

      expect(launchedQuests, ['sentence_lab']);
      verify(() => mockHapticService.selection()).called(1);
    });
  });

  group('Piece 9: DiscoveryDeck Small Screen & Accessibility Robustness', () {
    testWidgets('renders cleanly on 320dp small mobile (iPhone SE) without overflow', (tester) async {
      await tester.pumpWidget(createTestWidget(width: 320, height: 568));
      await tester.pumpAndSettle();

      expect(find.text('Smart Focus'), findsOneWidget);
      expect(find.text('Daily Workout'), findsOneWidget);
      expect(find.text('Rapid Recall'), findsOneWidget);
      expect(find.text('Sentence Lab'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with 1.3x accessibility text scale without overflow', (tester) async {
      await tester.pumpWidget(createTestWidget(textScale: 1.3));
      await tester.pumpAndSettle();

      expect(find.text('Smart Focus'), findsOneWidget);
      expect(find.text('Daily Workout'), findsOneWidget);
      expect(find.text('Rapid Recall'), findsOneWidget);
      expect(find.text('Sentence Lab'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in Light theme mode', (tester) async {
      await tester.pumpWidget(createTestWidget(brightness: Brightness.light));
      await tester.pumpAndSettle();

      expect(find.text('Smart Focus'), findsOneWidget);
      expect(find.text('Daily Workout'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Piece 9: DiscoveryDeck Daily Completion & Midnight Reset Tests', () {
    testWidgets('displays COMPLETED TODAY and COMPLETED tags when sequences finished today', (tester) async {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      SharedPreferences.setMockInitialValues({
        'vowl_sequence_completed_smart_recommendation_${testUser.id}': todayStr,
        'vowl_sequence_completed_daily_duo_${testUser.id}': todayStr,
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('COMPLETED TODAY ✓'), findsOneWidget);
      expect(find.text('COMPLETED ✓'), findsOneWidget);
      // Other uncompleted cells remain in default state
      expect(find.text('Speed Drill'), findsOneWidget);
      expect(find.text('Syntax'), findsOneWidget);
    });

    testWidgets('resets to normal state when completion date was yesterday', (tester) async {
      SharedPreferences.setMockInitialValues({
        'vowl_sequence_completed_smart_recommendation_${testUser.id}': '2020-01-01',
        'vowl_sequence_completed_daily_duo_${testUser.id}': '2020-01-01',
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ADAPTIVE AI'), findsOneWidget);
      expect(find.text('2 Steps'), findsOneWidget);
      expect(find.text('COMPLETED TODAY ✓'), findsNothing);
    });

    testWidgets('dynamic update via notifySequenceCompleted updates mounted widget without rebuild', (tester) async {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('ADAPTIVE AI'), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vowl_sequence_completed_smart_recommendation_${testUser.id}', todayStr);
      DiscoveryDeck.notifySequenceCompleted();
      await tester.pumpAndSettle();

      expect(find.text('COMPLETED TODAY ✓'), findsOneWidget);
    });
  });
}

