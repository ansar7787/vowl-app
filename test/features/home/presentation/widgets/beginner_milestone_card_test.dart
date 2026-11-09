import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/home/presentation/widgets/beginner_milestone_card.dart';

class MockHapticService extends Mock implements HapticService {}

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;

  setUp(() {
    mockHapticService = MockHapticService();
    mockLocaleService = MockLocaleService();

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));
    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer((inv) {
      final fallback = inv.namedArguments[#fallback] as String?;
      return fallback ?? (inv.positionalArguments.first as String);
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
    required VoidCallback onUnlockNow,
    double width = 393,
    double height = 852,
    ThemeMode themeMode = ThemeMode.dark,
  }) {
    return ScreenUtilInit(
      designSize: Size(width, height),
      builder: (context, _) => MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: BeginnerMilestoneCard(user: user, onUnlockNow: onUnlockNow),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'renders BeginnerMilestoneCard with title, subtitle, progress and bypass button',
    (tester) async {
      bool unlocked = false;
      const user = UserEntity(
        id: 'beginner_1',
        email: 'beg@vowl.app',
        completedLevels: {
          'flashcards': [1],
        },
      );

      await tester.pumpWidget(
        createSubject(user: user, onUnlockNow: () => unlocked = true),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Skill Arena & Tools Unlock at Level 2'),
        findsOneWidget,
      );
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('Explore all features now →'), findsOneWidget);

      await tester.tap(find.text('Explore all features now →'));
      await tester.pumpAndSettle();

      expect(unlocked, isTrue);
      verify(() => mockHapticService.selection()).called(1);
    },
  );

  testWidgets(
    'renders cleanly on 320dp small mobile screen without RenderFlex overflow',
    (tester) async {
      const user = UserEntity(id: 'beginner_small', email: 'small@vowl.app');

      await tester.pumpWidget(
        createSubject(user: user, onUnlockNow: () {}, width: 320, height: 568),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Skill Arena & Tools Unlock at Level 2'),
        findsOneWidget,
      );
    },
  );

  testWidgets('renders cleanly in Light theme mode', (tester) async {
    const user = UserEntity(id: 'beginner_light', email: 'light@vowl.app');

    await tester.pumpWidget(
      createSubject(user: user, onUnlockNow: () {}, themeMode: ThemeMode.light),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(BeginnerMilestoneCard), findsOneWidget);
  });
}
