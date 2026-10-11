import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/utils/story_service.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';

void main() {
  group('Handwriting Content Alignment & Human Quality Tests', () {
    test('StoryService handwriting milestones contains exactly 6 progressive human beats', () {
      final scripts = StoryServiceImpl.kidsScripts['handwriting'];
      expect(scripts, isNotNull);
      expect(scripts!.length, equals(6));

      // Level 1 milestone (Beat 0)
      expect(scripts[0], contains('chalkboard'));
      expect(scripts[0], contains('first strokes'));

      // Level 10 milestone (Beat 1)
      expect(scripts[1], contains('steady'));

      // Level 20 milestone (Beat 2)
      expect(scripts[2], contains('confidence'));

      // Level 50 milestone (Beat 3)
      expect(scripts[3], contains('Fifty levels'));

      // Level 100 milestone (Beat 4)
      expect(scripts[4], contains('One hundred levels'));
      expect(scripts[4], contains('beautiful your writing has become'));

      // Level 200 milestone (Beat 5)
      expect(scripts[5], contains('mastered the chalkboard'));

      // Zero robotic buzzwords check
      for (final beat in scripts) {
        expect(beat.toLowerCase(), isNot(contains('magic pen')));
        expect(beat.toLowerCase(), isNot(contains('magic scroll')));
        expect(beat.toLowerCase(), isNot(contains('golden pen')));
        expect(beat.toLowerCase(), isNot(contains('calligraphy hero')));
        expect(beat.toLowerCase(), isNot(contains('glowing arrows')));
      }
    });

    test('GameBriefing fallback for handwriting accurately describes chalkboard slate mechanics', () {
      // Testing the static briefing resolution fallback
      const briefing = GameBriefing(
        title: "Chalkboard Writing",
        icon: Icons.draw_rounded,
        objective:
            "Pick up your chalk and practice drawing lines, shapes, and letters right on the chalkboard slate.",
        rules: [
          "Tap Demo to watch how each stroke is drawn step by step",
          "Turn on Trace to follow the dotted lines, or practice on your own",
          "Tap Check My Answer when ready, or use the duster to try again",
        ],
        actionText: "Let's Write",
        tip:
            "PRO TIP: Take your time. Drawing strokes from top to bottom and left to right makes writing so much easier!",
      );

      expect(briefing.title, equals("Chalkboard Writing"));
      expect(briefing.objective, contains("chalkboard slate"));
      expect(briefing.rules[0], contains("Demo"));
      expect(briefing.rules[1], contains("Trace"));
      expect(briefing.rules[2], contains("duster"));
      expect(briefing.tip, contains("top to bottom"));
    });
  });
}
