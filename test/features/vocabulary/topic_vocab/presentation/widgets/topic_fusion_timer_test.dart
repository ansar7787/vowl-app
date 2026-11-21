import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_fusion_timer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  group('TopicFusionTimer', () {
    testWidgets('renders remaining seconds and linear progress', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TopicFusionTimer(
            remainingSeconds: 20,
            totalSeconds: 30,
            accentColor: Colors.deepPurple,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('20s'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('+5s'), findsNothing);
    });

    testWidgets('renders bonus time badge when bonusSecondsAdded > 0', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TopicFusionTimer(
            remainingSeconds: 25,
            totalSeconds: 30,
            accentColor: Colors.deepPurple,
            bonusSecondsAdded: 5,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('25s'), findsOneWidget);
      expect(find.text('+5s'), findsOneWidget);
    });

    testWidgets('renders urgent timer state when remainingSeconds <= 5', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TopicFusionTimer(
            remainingSeconds: 4,
            totalSeconds: 30,
            accentColor: Colors.deepPurple,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('4s'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('renders combo streak badge when comboMultiplier > 1', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TopicFusionTimer(
            remainingSeconds: 18,
            totalSeconds: 30,
            accentColor: Colors.deepPurple,
            comboMultiplier: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TIME LEFT'), findsOneWidget);
      expect(find.text('18s'), findsOneWidget);
      expect(find.text('2x COMBO'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    });
  });
}
