import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/photo_vocabulary/domain/entities/visual_object_target.dart';
import 'package:vowl/features/photo_vocabulary/presentation/widgets/visual_object_badges.dart';

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sl = GetIt.instance;

  setUp(() {
    sl.reset();
    sl.registerSingleton<HapticService>(MockHapticService());
    sl.registerSingleton<SoundService>(MockSoundService());
  });

  tearDown(() {
    sl.reset();
  });

  group('VisualObjectBadges Widget Tests', () {
    final targets = [
      VisualObjectTarget.fromLabel('Laptop', confidence: 0.96),
      VisualObjectTarget.fromLabel('Coffee cup', confidence: 0.88),
    ];

    testWidgets('renders badge chips for detected objects', (tester) async {
      await tester.pumpWidget(
        _wrap(
          VisualObjectBadges(
            objects: targets,
            selectedObject: targets.first,
            onSelectObject: (_) {},
            onStartChallenge: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Laptop'), findsWidgets);
      expect(find.text('Coffee cup'), findsOneWidget);
      expect(find.text('96%'), findsOneWidget);
      expect(find.text('88%'), findsOneWidget);
    });

    testWidgets('triggers onSelectObject when chip tapped', (tester) async {
      VisualObjectTarget? selected;

      await tester.pumpWidget(
        _wrap(
          VisualObjectBadges(
            objects: targets,
            selectedObject: targets.first,
            onSelectObject: (obj) => selected = obj,
            onStartChallenge: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Coffee cup'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.label, equals('Coffee cup'));
    });

    testWidgets('triggers onStartChallenge when snap challenge button tapped', (
      tester,
    ) async {
      bool challengeStarted = false;

      await tester.pumpWidget(
        _wrap(
          VisualObjectBadges(
            objects: targets,
            selectedObject: targets.first,
            onSelectObject: (_) {},
            onStartChallenge: () => challengeStarted = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final challengeBtn = find.text(
        'Play 3-Question Snap Challenge (+10 Coins)',
      );
      expect(challengeBtn, findsOneWidget);

      await tester.ensureVisible(challengeBtn);
      await tester.pumpAndSettle();
      await tester.tap(challengeBtn);
      await tester.pumpAndSettle();

      expect(challengeStarted, isTrue);
    });

    testWidgets('renders empty state safely when objects list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          VisualObjectBadges(
            objects: const [],
            selectedObject: null,
            onSelectObject: (_) {},
            onStartChallenge: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VisualObjectBadges), findsOneWidget);
      expect(
        find.text('Play 3-Question Snap Challenge (+10 Coins)'),
        findsNothing,
      );
    });
  });
}
