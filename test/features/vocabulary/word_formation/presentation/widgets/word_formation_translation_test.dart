import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_learn_compass.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_morph_core.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_sentence_slot.dart';

class MockTtsService extends Mock implements TtsService {}
class MockHapticService extends Mock implements HapticService {}
class MockSoundService extends Mock implements SoundService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTtsService mockTtsService;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    mockTtsService = MockTtsService();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();

    when(() => mockTtsService.speak(any(), rate: any(named: 'rate'), locale: any(named: 'locale'))).thenAnswer((_) async {});
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});

    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();

    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
  });

  tearDownAll(() {
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  group('Word Formation Translation & Audio Scaffolding', () {
    testWidgets('WordFormationMorphCore renders root definition and TranslateButtonWidget', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const WordFormationMorphCore(
            rootWord: 'DECIDE',
            rootMeaning: 'Come to a resolution or decision.',
            primaryColor: Colors.deepPurple,
            isDark: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ROOT WORD'), findsOneWidget);
      expect(find.text('DECIDE'), findsOneWidget);
      expect(find.text('Come to a resolution or decision.'), findsOneWidget);
      expect(find.byType(TranslateButtonWidget), findsOneWidget);
    });

    testWidgets('WordFormationSentenceSlot renders sentence and TranslateButtonWidget', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const WordFormationSentenceSlot(
            sentence: 'She is a very _______ manager.',
            rootWord: 'DECIDE',
            targetRole: 'Adjective',
            isAnswered: false,
            primaryColor: Colors.deepPurple,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ROOT: DECIDE'), findsOneWidget);
      expect(find.text('TARGET: ADJECTIVE'), findsOneWidget);
      expect(find.byType(TranslateButtonWidget), findsOneWidget);
    });

    testWidgets('WordFormationLearnCompass resets active direction to north on word change', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const WordFormationLearnCompass(
            northNoun: {'word': 'DECISION', 'role': 'Noun', 'rule': 'Add -sion', 'example': 'A good decision.'},
            eastAdjective: {'word': 'DECISIVE', 'role': 'Adjective', 'rule': 'Add -sive', 'example': 'A decisive leader.'},
            southAdverb: {'word': 'DECISIVELY', 'role': 'Adverb', 'rule': 'Add -ly', 'example': 'Acted decisively.'},
            westOpposite: {'word': 'INDECISIVE', 'role': 'Opposite', 'rule': 'Add in-', 'example': 'Felt indecisive.'},
            primaryColor: Colors.deepPurple,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('DECISION'), findsOneWidget);

      // Tap East (Adjective)
      await tester.tap(find.text('ADJECTIVE'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('DECISIVE'), findsOneWidget);

      // Now update widget with a new word (CONCLUDE)
      await tester.pumpWidget(
        buildTestableWidget(
          const WordFormationLearnCompass(
            northNoun: {'word': 'CONCLUSION', 'role': 'Noun', 'rule': 'Add -sion', 'example': 'A final conclusion.'},
            eastAdjective: {'word': 'CONCLUSIVE', 'role': 'Adjective', 'rule': 'Add -sive', 'example': 'Conclusive evidence.'},
            southAdverb: {'word': 'CONCLUSIVELY', 'role': 'Adverb', 'rule': 'Add -ly', 'example': 'Proven conclusively.'},
            westOpposite: {'word': 'INCONCLUSIVE', 'role': 'Opposite', 'rule': 'Add in-', 'example': 'Inconclusive results.'},
            primaryColor: Colors.deepPurple,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Must have reset back to North (CONCLUSION)
      expect(find.text('CONCLUSION'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
