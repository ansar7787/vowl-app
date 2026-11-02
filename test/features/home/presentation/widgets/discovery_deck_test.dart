import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
    testWidgets('renders Flagship Hero Card: For You (Adaptive)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('For You'), findsOneWidget);
      expect(find.text('ADAPTIVE'), findsOneWidget);
      expect(find.text('Personalized to your practice'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);
    });

    testWidgets('renders 3-Cell Superpower Row: Daily Duo, Speed Blitz, Grammar Pro', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Daily Duo'), findsOneWidget);
      expect(find.text('2 Quests'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_motion_rounded), findsOneWidget);

      expect(find.text('Speed Blitz'), findsOneWidget);
      expect(find.text('3 Quests'), findsNWidgets(2)); // Speed Blitz and Grammar Pro both have 3 Quests
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);

      expect(find.text('Grammar Pro'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
    });
  });

  group('Piece 9: DiscoveryDeck Interaction & Navigation Tests', () {
    testWidgets('tapping For You hero card launches smart_recommendation and triggers haptic', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('For You'));
      await tester.pumpAndSettle();

      expect(launchedQuests, ['smart_recommendation']);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('tapping Daily Duo subcell launches daily_duo and triggers haptic', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Daily Duo'));
      await tester.pumpAndSettle();

      expect(launchedQuests, ['daily_duo']);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('tapping Speed Blitz subcell launches speed_blitz and triggers haptic', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Speed Blitz'));
      await tester.pumpAndSettle();

      expect(launchedQuests, ['speed_blitz']);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('tapping Grammar Pro subcell launches grammar_pro and triggers haptic', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Grammar Pro'));
      await tester.pumpAndSettle();

      expect(launchedQuests, ['grammar_pro']);
      verify(() => mockHapticService.selection()).called(1);
    });
  });

  group('Piece 9: DiscoveryDeck Small Screen & Accessibility Robustness', () {
    testWidgets('renders cleanly on 320dp small mobile (iPhone SE) without overflow', (tester) async {
      await tester.pumpWidget(createTestWidget(width: 320, height: 568));
      await tester.pumpAndSettle();

      expect(find.text('For You'), findsOneWidget);
      expect(find.text('Daily Duo'), findsOneWidget);
      expect(find.text('Speed Blitz'), findsOneWidget);
      expect(find.text('Grammar Pro'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with 1.3x accessibility text scale without overflow', (tester) async {
      await tester.pumpWidget(createTestWidget(textScale: 1.3));
      await tester.pumpAndSettle();

      expect(find.text('For You'), findsOneWidget);
      expect(find.text('Daily Duo'), findsOneWidget);
      expect(find.text('Speed Blitz'), findsOneWidget);
      expect(find.text('Grammar Pro'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in Light theme mode', (tester) async {
      await tester.pumpWidget(createTestWidget(brightness: Brightness.light));
      await tester.pumpAndSettle();

      expect(find.text('For You'), findsOneWidget);
      expect(find.text('Daily Duo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

