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
    {
      'id': 'VOC_TOPICVOCAB_L1_LEARN_TEST',
      'level': 1,
      'conceptTitle': 'Thermal Spectrum: Heat vs Cold',
      'topicEmoji': '🌡️',
      'topicBuckets': ['Intense Heat', 'Extreme Cold'],
      'contrastInsight': 'Notice differences between heat and cold.',
      'categories': [
        {
          'name': 'Intense Heat',
          'emoji': '🔥',
          'desc': 'High thermal energy terms.',
          'words': [
            {'word': 'Boiling', 'ipa': '/ˈbɔɪ.lɪŋ/', 'def': 'Liquid heated to 100°C.', 'coll': 'boiling water', 'int': 'Extreme'},
          ]
        },
        {
          'name': 'Extreme Cold',
          'emoji': '❄️',
          'desc': 'Sub-zero terms.',
          'words': [
            {'word': 'Freezing', 'ipa': '/ˈfriː.zɪŋ/', 'def': 'Ice cold below 0°C.', 'coll': 'freezing cold', 'int': 'Extreme'},
          ]
        }
      ]
    }
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
    when(() => mockHaptics.success()).thenAnswer((_) async {});

    when(() => mockTts.stop()).thenAnswer((_) async {});
    when(() => mockTts.speak(any(), rate: any(named: 'rate'), locale: any(named: 'locale'))).thenAnswer((_) async {});

    await di.sl.reset();
    di.sl.registerSingleton<HapticService>(mockHaptics);
    di.sl.registerSingleton<SoundService>(mockSounds);
    di.sl.registerSingleton<TtsService>(mockTts);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: child,
          ),
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
      expect(find.text('Topic Vocab Lab'), findsOneWidget);
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
