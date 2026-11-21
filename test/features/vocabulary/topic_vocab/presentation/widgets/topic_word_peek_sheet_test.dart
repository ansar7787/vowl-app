import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_word_peek_sheet.dart';

class MockTtsService extends Mock implements TtsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockTtsService mockTts;

  setUpAll(() {
    mockTts = MockTtsService();
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    di.sl.registerSingleton<TtsService>(mockTts);
    when(() => mockTts.speak(any())).thenAnswer((_) async {});
    when(() => mockTts.preWarm()).thenAnswer((_) async {});
  });

  tearDownAll(() {
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
  });

  testWidgets('TopicWordPeekSheet renders word, theme, definition, and dismisses', (tester) async {
    VowlMotion.lowAnimationModeOverride.value = true;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  TopicWordPeekSheet.show(
                    ctx,
                    word: 'Scorching',
                    definition: 'Extremely hot; parching the surface of something.',
                    categoryHint: 'Intense Heat',
                    accentColor: Colors.deepOrange,
                  );
                },
                child: const Text('Open Peek'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap to open sheet and settle route animation
    await tester.tap(find.text('Open Peek'));
    await tester.pumpAndSettle();

    expect(find.text('Scorching'), findsOneWidget);
    expect(find.text('Theme: Intense Heat'), findsOneWidget);
    expect(find.text('Extremely hot; parching the surface of something.'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);

    // Tap dismiss and settle dismiss animation
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text('Got it'), findsNothing);
  });
}
