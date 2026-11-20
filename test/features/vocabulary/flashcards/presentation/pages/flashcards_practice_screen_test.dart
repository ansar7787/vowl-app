import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_practice_screen.dart';

class MockHapticService extends Mock implements HapticService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHaptic;

  setUp(() {
    mockHaptic = MockHapticService();
    when(() => mockHaptic.selection()).thenAnswer((_) async {});
    when(() => mockHaptic.success()).thenAnswer((_) async {});
    when(() => mockHaptic.error()).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerLazySingleton<HapticService>(() => mockHaptic);
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(home: child),
    );
  }

  group('FlashcardsPracticeScreen', () {
    testWidgets(
      'assembles chunks, checks word, and completes collocation challenge',
      (tester) async {
        tester.view.physicalSize = const Size(375 * 2, 812 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestableWidget(const FlashcardsPracticeScreen(level: 1)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(FlashcardsPracticeScreen), findsOneWidget);
        expect(find.text('COMPLETE THE CONTEXT SENTENCE'), findsOneWidget);
        expect(find.text('AVAILABLE CHUNKS'), findsOneWidget);

        // Tap chunks: AU, THEN, TIC with debounce clearance
        expect(find.text('AU'), findsOneWidget);
        expect(find.text('THEN'), findsOneWidget);
        expect(find.text('TIC'), findsOneWidget);

        await tester.ensureVisible(find.text('AU'));
        await tester.tap(find.text('AU'));
        await tester.pump(const Duration(milliseconds: 600));

        await tester.ensureVisible(find.text('THEN'));
        await tester.tap(find.text('THEN'));
        await tester.pump(const Duration(milliseconds: 600));

        await tester.ensureVisible(find.text('TIC'));
        await tester.tap(find.text('TIC'));
        await tester.pump(const Duration(milliseconds: 600));

        // Tap Check Word
        expect(find.text('Check Word'), findsOneWidget);
        await tester.tap(find.text('Check Word'));
        await tester.pumpAndSettle();

        // Collocation Challenge should now be visible
        expect(find.textContaining('partner'), findsOneWidget);
        expect(find.text('authentic cuisine'), findsOneWidget);

        // Select authentic cuisine
        await tester.ensureVisible(find.text('authentic cuisine'));
        await tester.tap(find.text('authentic cuisine'));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        verify(() => mockHaptic.success()).called(2);
      },
    );
  });
}
