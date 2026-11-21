import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/vocabulary/topic_vocab/domain/entities/topic_learn_quest.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/pages/topic_vocab_learn_screen.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_blueprint_tree.dart';

class MockHapticService extends Mock implements HapticService {}
class MockSoundService extends Mock implements SoundService {}
class MockTtsService extends Mock implements TtsService {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHaptics;
  late MockSoundService mockSounds;
  late MockTtsService mockTts;
  late MockAuthBloc mockAuthBloc;

  final testQuests = [
    const TopicLearnQuest(
      id: 'VOC_TOPICVOCAB_L1_LEARN_TEST',
      level: 1,
      conceptTitle: 'Thermal Spectrum: Heat vs Cold',
      topicEmoji: '🌡️',
      contrastInsight: 'Notice differences between heat and cold.',
      categories: [
        TopicCategory(
          name: 'Intense Heat',
          emoji: '🔥',
          description: 'High thermal energy terms.',
          words: [
            TopicWordDetail(word: 'Boiling', ipa: '/ˈbɔɪ.lɪŋ/', definition: 'Liquid heated to 100°C.', collocation: 'boiling water'),
          ],
        ),
        TopicCategory(
          name: 'Extreme Cold',
          emoji: '❄️',
          description: 'Sub-zero terms.',
          words: [
            TopicWordDetail(word: 'Freezing', ipa: '/ˈfriː.zɪŋ/', definition: 'Ice cold below 0°C.', collocation: 'freezing cold'),
          ],
        ),
      ],
    ),
  ];

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockHaptics = MockHapticService();
    mockSounds = MockSoundService();
    mockTts = MockTtsService();
    mockAuthBloc = MockAuthBloc();

    when(() => mockHaptics.selection()).thenAnswer((_) async {});
    when(() => mockHaptics.light()).thenAnswer((_) async {});
    when(() => mockHaptics.heavy()).thenAnswer((_) async {});
    when(() => mockHaptics.warning()).thenAnswer((_) async {});
    when(() => mockHaptics.error()).thenAnswer((_) async {});
    when(() => mockSounds.playCorrect(comboStep: any(named: 'comboStep'))).thenAnswer((_) async {});
    when(() => mockTts.speak(any())).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();

    di.sl.registerSingleton<HapticService>(mockHaptics);
    di.sl.registerSingleton<SoundService>(mockSounds);
    di.sl.registerSingleton<TtsService>(mockTts);
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  group('TopicVocabLearnScreen', () {
    testWidgets('renders topic blueprint tree and handles navigation', (tester) async {
      await tester.pumpWidget(buildTestableWidget(TopicVocabLearnScreen(level: 1, initialQuests: testQuests)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TopicBlueprintTree), findsOneWidget);
      expect(find.text('Topic Vocabulary'), findsOneWidget);
      expect(find.text('Thermal Spectrum: Heat vs Cold'), findsOneWidget);

      final actionFinder = find.textContaining('Start Practice');
      expect(actionFinder, findsOneWidget);
      await tester.tap(actionFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      verify(() => mockHaptics.light()).called(1);
    });
  });
}
