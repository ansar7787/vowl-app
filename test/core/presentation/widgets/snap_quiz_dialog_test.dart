import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/snap_quiz_dialog.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/sound_service.dart';

class MockHapticService extends Mock implements HapticService {}
class MockSoundService extends Mock implements SoundService {}

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    minTextAdapt: true,
    builder: (context, _) => MaterialApp(
      home: Scaffold(
        body: child,
      ),
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

  final quests = [
    const GameQuest(
      id: 'q1',
      instruction: 'Select definition for "Exit":',
      targetWord: 'Exit',
      options: ['A way out of a building', 'A piece of furniture', 'A food item'],
      correctAnswerIndex: 0,
      difficulty: 1,
    ),
    const GameQuest(
      id: 'q2',
      instruction: 'Phonetics for "Exit":',
      targetWord: 'Exit',
      options: ['Two syllables', 'Silent consonants', 'Monotone vowel'],
      correctAnswerIndex: 0,
      difficulty: 1,
    ),
    const GameQuest(
      id: 'q3',
      instruction: 'Complete the sentence:',
      targetWord: 'Exit',
      sentence: 'Please use the emergency ______.',
      options: ['Exit', 'Apple', 'Window'],
      correctAnswerIndex: 0,
      difficulty: 1,
    ),
  ];

  group('SnapQuizDialog Widget Tests', () {
    testWidgets('renders questions sequentially and displays victory view on completion', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => SnapQuizDialog.show(ctx, quests: quests),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Q1 is displayed
      expect(find.text('Select definition for "Exit":'), findsOneWidget);
      expect(find.text('A way out of a building'), findsOneWidget);

      // Select correct answer for Q1
      await tester.tap(find.text('A way out of a building'));
      await tester.pump(const Duration(milliseconds: 950));
      await tester.pumpAndSettle();

      // Q2 is displayed
      expect(find.text('Phonetics for "Exit":'), findsOneWidget);
      expect(find.text('Two syllables'), findsOneWidget);

      // Select correct answer for Q2
      await tester.tap(find.text('Two syllables'));
      await tester.pump(const Duration(milliseconds: 950));
      await tester.pumpAndSettle();

      // Q3 is displayed
      expect(find.text('Complete the sentence:'), findsOneWidget);
      expect(find.text('Please use the emergency ______.'), findsOneWidget);

      // Select correct answer for Q3
      await tester.tap(find.text('Exit'));
      await tester.pump(const Duration(milliseconds: 950));
      await tester.pumpAndSettle();

      // Victory Content is displayed!
      expect(find.text('CHALLENGE MASTERED!'), findsOneWidget);
      expect(find.text('+10 COINS ADDED'), findsOneWidget);
      expect(find.text('Keep Exploring Scanned Words'), findsOneWidget);
      expect(find.text('Done & Return Home'), findsOneWidget);

      // Tap "Keep Exploring Scanned Words"
      await tester.tap(find.text('Keep Exploring Scanned Words'));
      await tester.pumpAndSettle();

      // Dialog dismissed, parent still mounted
      expect(find.text('CHALLENGE MASTERED!'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('X button closes dialog safely', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => SnapQuizDialog.show(ctx, quests: quests),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Select definition for "Exit":'), findsOneWidget);

      // Tap close X button
      final closeBtn = find.byType(IconButton);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.text('Select definition for "Exit":'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });
  });
}

