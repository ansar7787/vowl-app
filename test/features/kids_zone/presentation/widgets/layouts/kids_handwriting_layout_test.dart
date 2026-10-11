import 'package:flutter/material.dart' hide Ink;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/widgets/handwriting/handwriting_canvas.dart';

class MockHapticService extends Mock implements HapticService {}

void main() {
  late MockHapticService mockHapticService;

  setUp(() {
    mockHapticService = MockHapticService();
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
  });

  Widget createTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 844,
            child: child,
          ),
        ),
      ),
    );
  }

  group('HandwritingCanvas Widget Tests', () {
    testWidgets('renders chalkboard canvas, guidelines, and slate ledge toolbar', (tester) async {
      Ink? receivedInk;
      bool cleared = false;

      await tester.pumpWidget(
        createTestWidget(
          HandwritingCanvas(
            ghostText: 'A',
            showGuidelines: true,
            initialShowGuide: true,
            onInkUpdated: (ink) => receivedInk = ink,
            onClear: () => cleared = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check toolbar elements
      expect(find.text('Chalk'), findsOneWidget);
      expect(find.text('Trace'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      // Verify canvas interaction (drag / pan two strokes)
      final canvasFinder = find.byType(GestureDetector).first;
      await tester.drag(canvasFinder, const Offset(0, 50));
      await tester.pumpAndSettle();
      await tester.drag(canvasFinder, const Offset(50, 0));
      await tester.pumpAndSettle();

      expect(receivedInk, isNotNull);
      expect(receivedInk!.strokes.length, equals(2));

      // Tap Undo (removes 1 stroke, 1 stroke remains)
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(receivedInk!.strokes.length, equals(1));

      // Tap Clear (clears the remaining stroke)
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(cleared, isTrue);
    });

    testWidgets('toggles tracing guide visibility', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          HandwritingCanvas(
            ghostText: 'CAT',
            onInkUpdated: (_) {},
            onClear: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final traceButton = find.text('Trace');
      expect(traceButton, findsOneWidget);

      await tester.tap(traceButton);
      await tester.pumpAndSettle();
      verify(() => mockHapticService.selection()).called(1);
    });
  });
}
