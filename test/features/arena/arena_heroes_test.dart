import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_context_blitz_hero.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_discipline_strip.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_option_tile.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_phrase_duel_hero.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_score_hud.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_sentence_strike_hero.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_word_clash_hero.dart';

Widget _wrapWithScreenUtil(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(393, 852),
    builder: (_, _) => MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  const dummyState = ArenaDuelState(
    currentQuestionIndex: 0,
    myScore: 120,
    rivalScore: 80,
    timeRemaining: 12,
    comboStreak: 2,
  );

  group('Arena Heroes & Option Tiles', () {
    testWidgets('ArenaWordClashHero renders synonym target word correctly', (
      tester,
    ) async {
      const q = ArenaQuestion(
        question: 'Select the synonym of "ABUNDANT":',
        options: ['Plentiful', 'Scarce', 'Few', 'Little'],
        correctIndex: 0,
        explanation: 'Abundant means existing in large quantities.',
        discipline: 'word_clash',
      );

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          const ArenaWordClashHero(
            q: q,
            state: dummyState,
            isDark: false,
            isMidnight: false,
            borderColor: AppColors.slate200,
            textPrimary: AppColors.slate900,
            textSecondary: AppColors.slate500,
          ),
        ),
      );

      expect(find.text('ABUNDANT'), findsOneWidget);
      expect(find.text('SELECT THE CLOSEST SYNONYM TO:'), findsOneWidget);
    });

    testWidgets('ArenaPhraseDuelHero renders idiom question correctly', (
      tester,
    ) async {
      const q = ArenaQuestion(
        question: 'What is the meaning of the idiom "Break the ice"?',
        options: [
          'Make people comfortable',
          'Freeze',
          'Crack glass',
          'Get angry',
        ],
        correctIndex: 0,
        explanation:
            'Break the ice means to initiate conversation in a social setting.',
        discipline: 'phrase_duel',
      );

      await tester.pumpWidget(
        _wrapWithScreenUtil(
          const ArenaPhraseDuelHero(
            q: q,
            state: dummyState,
            isDark: true,
            isMidnight: false,
            borderColor: AppColors.slate800,
            textPrimary: Colors.white,
            textSecondary: AppColors.slate400,
          ),
        ),
      );

      expect(find.text('DECIPHER THE FIGURATIVE EXPRESSION:'), findsOneWidget);
      expect(
        find.text('What is the meaning of the idiom "Break the ice"?'),
        findsOneWidget,
      );
    });

    testWidgets(
      'ArenaSentenceStrikeHero renders academic sentence question correctly',
      (tester) async {
        const q = ArenaQuestion(
          question: 'The research findings ___ the initial hypothesis.',
          options: ['corroborate', 'confuse', 'ignore', 'deny'],
          correctIndex: 0,
          explanation:
              'Corroborate means to confirm or give support to a statement.',
          discipline: 'sentence_strike',
        );

        await tester.pumpWidget(
          _wrapWithScreenUtil(
            const ArenaSentenceStrikeHero(
              q: q,
              state: dummyState,
              isDark: false,
              isMidnight: false,
              borderColor: AppColors.slate200,
              textPrimary: AppColors.slate900,
              textSecondary: AppColors.slate500,
            ),
          ),
        );

        expect(
          find.text('SELECT THE PRECISE GRAMMATICAL & REGISTER FIT:'),
          findsOneWidget,
        );
        expect(
          find.text('The research findings ___ the initial hypothesis.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ArenaContextBlitzHero renders context clues question correctly',
      (tester) async {
        const q = ArenaQuestion(
          question:
              'Despite the chaotic meeting, the diplomat remained completely ___.',
          options: ['unflappable', 'erratic', 'belligerent', 'anxious'],
          correctIndex: 0,
          explanation: 'Unflappable means calm under pressure.',
          discipline: 'context_blitz',
        );

        await tester.pumpWidget(
          _wrapWithScreenUtil(
            const ArenaContextBlitzHero(
              q: q,
              state: dummyState,
              isDark: false,
              isMidnight: false,
              borderColor: AppColors.slate200,
              textPrimary: AppColors.slate900,
              textSecondary: AppColors.slate500,
            ),
          ),
        );

        expect(
          find.text('ANALYZE CONTEXT CLUES & INFER THE MISSING MEANING:'),
          findsOneWidget,
        );
        expect(find.textContaining('remained completely'), findsOneWidget);
      },
    );

    testWidgets(
      'ArenaGridOptionTile renders option and fires callback on tap',
      (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          _wrapWithScreenUtil(
            ArenaGridOptionTile(
              index: 0,
              text: 'Plentiful',
              isAnswered: false,
              selectedOption: null,
              correctIndex: 0,
              isDark: false,
              borderColor: AppColors.slate200,
              textPrimary: AppColors.slate900,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        );

        expect(find.text('Plentiful'), findsOneWidget);
        expect(find.text('A'), findsOneWidget);

        await tester.tap(find.byType(ArenaGridOptionTile));
        expect(tapped, true);
      },
    );

    testWidgets(
      'ArenaListOptionTile renders option and fires callback on tap',
      (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          _wrapWithScreenUtil(
            ArenaListOptionTile(
              index: 1,
              text: 'Make people comfortable',
              isAnswered: false,
              selectedOption: null,
              correctIndex: 1,
              isDark: false,
              borderColor: AppColors.slate200,
              textPrimary: AppColors.slate900,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        );

        expect(find.text('Make people comfortable'), findsOneWidget);
        expect(find.text('B'), findsOneWidget);

        await tester.tap(find.byType(ArenaListOptionTile));
        expect(tapped, true);
      },
    );

    testWidgets(
      'ArenaScoreHud displays names, scores, timer, and combo streak',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithScreenUtil(
            const ArenaScoreHud(
              myName: 'Player 1',
              myScore: 240,
              rivalName: 'Rival Bot',
              rivalScore: 180,
              currentQuestionIndex: 2,
              totalQuestions: 5,
              timeRemaining: 10,
              isDark: true,
              isAiRival: true,
              aiTierLabel: 'MED',
              animateTimer: false,
              comboStreak: 3,
            ),
          ),
        );

        expect(find.text('Player 1'), findsOneWidget);
        expect(find.text('240 pts'), findsOneWidget);
        expect(find.text('Rival Bot'), findsOneWidget);
        expect(find.text('180 pts'), findsOneWidget);
        expect(find.text('🔥×3'), findsOneWidget);
        expect(find.text('MED'), findsOneWidget);
      },
    );

    testWidgets(
      'ArenaDisciplineStrip renders animated discipline label and round count',
      (tester) async {
        const q = ArenaQuestion(
          question: 'Select the synonym of "VIBRANT":',
          options: ['Lively', 'Dull', 'Quiet', 'Dark'],
          correctIndex: 0,
          explanation: 'Vibrant means full of energy and life.',
          discipline: 'word_clash',
        );

        await tester.pumpWidget(
          _wrapWithScreenUtil(
            const ArenaDisciplineStrip(
              question: q,
              currentRound: 3,
              totalRounds: 5,
              isDark: false,
            ),
          ),
        );

        expect(find.text('WORD CLASH • SYNONYM'), findsOneWidget);
        expect(find.text('ROUND 3 OF 5'), findsOneWidget);
      },
    );
  });
}
