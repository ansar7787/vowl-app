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
import 'package:vowl/features/vocabulary/topic_vocab/presentation/pages/topic_vocab_practice_screen.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_category_tray.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_fusion_tile.dart';

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

  group('TopicVocabPracticeScreen', () {
    testWidgets('renders category trays, word pool, and handles sorting interaction', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(const TopicVocabPracticeScreen(level: 1)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TopicCategoryTray), findsWidgets);
      expect(find.text('Practice: Word Groups'), findsOneWidget);
      expect(find.byType(TopicFusionTile), findsWidgets);

      // Tap on a word tile from the pool
      final tiles = find.byType(TopicFusionTile);
      if (tiles.evaluate().isNotEmpty) {
        await tester.tap(tiles.first);
        await tester.pumpAndSettle();
      }
    });
  });
}
