import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/utils/story_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kids Verbs Game Instruction Service', () {
    testWidgets('Level 1 returns accurate, natural, human briefing without gamer buzzwords', (tester) async {
      late GameBriefing briefing;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              briefing = GameInstructionService.getBriefing(
                context,
                null,
                'verbs',
                level: 1,
              );
              return const Scaffold();
            },
          ),
        ),
      );

      expect(briefing.title, 'Action Time!');
      expect(briefing.icon, Icons.directions_run_rounded);
      expect(briefing.objective, contains('scoreboard'));
      expect(briefing.objective, contains('sports ball'));
      expect(briefing.rules.length, 3);
      expect(briefing.rules[0], contains('scoreboard'));
      expect(briefing.rules[1], contains('drag'));
      expect(briefing.rules[2], contains('speaker'));
      expect(briefing.actionText, 'Play Ball!');
      expect(briefing.tip, startsWith('Tip:'));
      expect(briefing.tip, isNot(contains('PRO TIP')));
    });

    testWidgets('Level 100 returns special milestone briefing celebrating 100 levels', (tester) async {
      late GameBriefing briefing;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              briefing = GameInstructionService.getBriefing(
                context,
                null,
                'verbs',
                level: 100,
              );
              return const Scaffold();
            },
          ),
        ),
      );

      expect(briefing.title, contains('Action Champion!'));
      expect(briefing.icon, Icons.emoji_events_rounded);
      expect(briefing.objective, contains('Level 100'));
      expect(briefing.rules.length, 3);
      expect(briefing.rules[2], contains('100 levels'));
      expect(briefing.actionText, 'Play Level 100');
      expect(briefing.tip, startsWith('Tip:'));
      expect(briefing.tip, contains('champion'));
    });
  });

  group('Kids Verbs Story Service', () {
    final storyService = StoryService();

    testWidgets('Level 1 resolves warm, human stadium story beat', (tester) async {
      StoryBeat? beat;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              beat = storyService.getStoryBeat(context, 'verbs', 1);
              return const Scaffold();
            },
          ),
        ),
      );

      expect(beat, isNotNull);
      expect(beat!.mascotEmoji, '🏃');
      expect(beat!.text, contains('Welcome to the stadium!'));
      expect(beat!.text, contains('Run, jump, and play'));
      expect(beat!.text, isNot(contains('Action Hero')));
      expect(beat!.text, isNot(contains('whirlwind')));
    });

    testWidgets('Level 100 resolves century milestone story beat', (tester) async {
      StoryBeat? beat;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              beat = storyService.getStoryBeat(context, 'verbs', 100);
              return const Scaffold();
            },
          ),
        ),
      );

      expect(beat, isNotNull);
      expect(beat!.mascotEmoji, '🏃');
      expect(beat!.text, contains('One hundred levels completed!'));
      expect(beat!.text, contains('Amazing achievement!'));
      expect(beat!.text, isNot(contains('Action Arena')));
    });

    testWidgets('All milestones (1, 10, 20, 50, 100, 200) resolve cleanly without buzzwords', (tester) async {
      final milestoneLevels = [1, 10, 20, 50, 100, 200];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              for (final level in milestoneLevels) {
                final beat = storyService.getStoryBeat(context, 'verbs', level);
                expect(beat, isNotNull, reason: 'Level $level should have a valid story beat');
                expect(beat!.text, isNotEmpty);
                // Ensure no robotic buzzwords
                expect(beat.text, isNot(contains('Action Hero')));
                expect(beat.text, isNot(contains('Action Arena')));
                expect(beat.text, isNot(contains('whirlwind')));
                expect(beat.text, isNot(contains('art of doing')));
              }
              return const Scaffold();
            },
          ),
        ),
      );
    });
  });
}

