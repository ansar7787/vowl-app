import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/features/vocabulary/topic_vocab/domain/entities/topic_learn_quest.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_word_item_card.dart';

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
    when(() => mockTts.speak(any(), rate: any(named: 'rate'), locale: any(named: 'locale'))).thenAnswer((_) async {});
    when(() => mockTts.preWarm(locale: any(named: 'locale'), preset: any(named: 'preset'))).thenAnswer((_) async {});
  });

  tearDownAll(() {
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
  });

  testWidgets('TopicWordItemCard renders word, ipa, definition, collocation, TTS and translate', (tester) async {
    const wordDetail = TopicWordDetail(
      word: 'Boiling',
      ipa: '/ˈbɔɪ.lɪŋ/',
      definition: 'Liquid heated to 100°C.',
      collocation: 'boiling water',
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => const MaterialApp(
          home: Scaffold(
            body: TopicWordItemCard(
              word: wordDetail,
              accentColor: Colors.deepOrange,
              isDark: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Boiling'), findsOneWidget);
    expect(find.text('/ˈbɔɪ.lɪŋ/'), findsOneWidget);
    expect(find.text('Liquid heated to 100°C.'), findsOneWidget);
    expect(find.text('boiling water'), findsOneWidget);
    expect(find.byType(TtsSpeakerButtonWidget), findsOneWidget);
    expect(find.byType(TranslateButtonWidget), findsOneWidget);
  });
}
