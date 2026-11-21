import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_cluster_banner.dart';

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
  });

  tearDownAll(() {
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
  });

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child,
          ),
        ),
      ),
    );
  }

  group('TopicClusterBanner', () {
    testWidgets('renders category, emoji, word list and checkmark', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TopicClusterBanner(
            categoryName: 'Intense Heat',
            emoji: '🔥',
            words: ['Boiling', 'Scorching', 'Steaming'],
            explanation: 'Words relating to extreme thermal energy.',
            accentColor: Colors.deepOrange,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Intense Heat'), findsOneWidget);
      expect(find.byIcon(Icons.whatshot_rounded), findsOneWidget);
      expect(find.text('Boiling • Scorching • Steaming'), findsOneWidget);
      expect(find.text('Words relating to extreme thermal energy.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders authentic collocations spotlight with link icon', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TopicClusterBanner(
            categoryName: 'Intense Heat',
            emoji: '🔥',
            words: ['Boiling', 'Scorching', 'Steaming'],
            collocations: ['boiling kettle', 'scorching sun', 'steaming mug'],
            accentColor: Colors.deepOrange,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('boiling kettle • scorching sun • steaming mug'), findsOneWidget);
      expect(find.byIcon(Icons.link_rounded), findsOneWidget);
    });
  });
}
