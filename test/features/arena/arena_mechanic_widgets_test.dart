import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/domain/entities/arena_match_record.dart';
import 'package:vowl/features/arena/domain/entities/arena_rank.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_match_history_tile.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_rank_badge.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_rematch_overlay.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_result_dialog.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_round_strip.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_mcq_mechanic.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_rapid_judge_mechanic.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_round_announce_card.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_sentence_build_mechanic.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_speed_spell_mechanic.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_spot_error_mechanic.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_type_duel_mechanic.dart';
import 'package:vowl/features/arena/presentation/widgets/mechanics/arena_word_snap_mechanic.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(393, 852),
    builder: (_, _) => MaterialApp(
      home: Scaffold(body: SafeArea(child: child)),
    ),
  );
}

void main() {
  const baseState = ArenaDuelState(
    currentQuestionIndex: 0,
    myScore: 120,
    rivalScore: 90,
    timeRemaining: 15,
  );

  group('7 Independent Arena Mechanic Widgets', () {
    testWidgets('ArenaWordSnapMechanic places, undoes, clears, and submits', (
      tester,
    ) async {
      String? submitted;
      const challenge = ArenaChallenge(
        mechanic: ArenaMechanicType.wordSnap,
        id: 'WS_T1',
        prompt: 'Unscramble: word for happy',
        correctAnswer: 'glad',
        scrambledLetters: 'DLGA',
        hint: '4 letters',
        explanation: 'Glad means happy.',
      );

      await tester.pumpWidget(
        _wrap(
          ArenaWordSnapMechanic(
            challenge: challenge,
            state: baseState,
            isDark: false,
            isMidnight: false,
            borderColor: AppColors.slate200,
            textPrimary: AppColors.slate900,
            textSecondary: AppColors.slate500,
            onSubmitWord: (w) => submitted = w,
          ),
        ),
      );

      // Tap D then clear all
      await tester.tap(find.text('D').first);
      await tester.pump();
      expect(find.text('Clear All'), findsOneWidget);
      await tester.tap(find.text('Clear All'));
      await tester.pump();
      expect(find.text('Clear All'), findsNothing);

      // Place all 4 letters in order G-L-A-D -> auto-submits
      for (final ch in ['G', 'L', 'A', 'D']) {
        await tester.tap(find.text(ch).last);
        await tester.pump();
      }
      expect(submitted, 'GLAD');
    });

    testWidgets('ArenaTypeDuelMechanic shows rival typing progress & submits', (
      tester,
    ) async {
      String? submitted;
      const challenge = ArenaChallenge(
        mechanic: ArenaMechanicType.typeDuel,
        id: 'TD_T1',
        prompt: 'A feeling of great triumph',
        correctAnswer: 'victory',
        letterCount: 7,
        explanation: 'Victory.',
      );

      await tester.pumpWidget(
        _wrap(
          ArenaTypeDuelMechanic(
            challenge: challenge,
            state: baseState.copyWith(rivalCharactersTyped: 4),
            isDark: false,
            isMidnight: false,
            borderColor: AppColors.slate200,
            textPrimary: AppColors.slate900,
            textSecondary: AppColors.slate500,
            onTextChanged: (_) {},
            onSubmitWord: (w) => submitted = w,
          ),
        ),
      );

      expect(find.text('4/7'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'victory');
      await tester.pump();
      await tester.tap(find.text('Submit Word'));
      await tester.pump();
      expect(submitted, 'victory');
    });

    testWidgets('ArenaRapidJudgeMechanic displays sentence and fires CORRECT/WRONG', (
      tester,
    ) async {
      int? lastIndex;
      bool? lastChoice;
      const challenge = ArenaChallenge(
        mechanic: ArenaMechanicType.rapidJudge,
        id: 'RJ_T1',
        prompt: 'Judge grammar',
        correctAnswer: '',
        explanation: 'Grammar check.',
        rapidItems: [
          RapidJudgeItem(
            sentence: "She don't know.",
            isCorrect: false,
            rule: "Use doesn't.",
          ),
          RapidJudgeItem(
            sentence: 'They work hard.',
            isCorrect: true,
            rule: 'Correct.',
          ),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          ArenaRapidJudgeMechanic(
            challenge: challenge,
            state: baseState.copyWith(rapidCurrentItemIndex: 0),
            isDark: false,
            isMidnight: false,
            borderColor: AppColors.slate200,
            textPrimary: AppColors.slate900,
            textSecondary: AppColors.slate500,
            onJudgeItem: (idx, ok) {
              lastIndex = idx;
              lastChoice = ok;
            },
          ),
        ),
      );

      expect(find.text("She don't know."), findsOneWidget);
      await tester.tap(find.text('WRONG'));
      await tester.pump();
      expect(lastIndex, 0);
      expect(lastChoice, isFalse);
    });

    testWidgets('ArenaSentenceBuildMechanic places word tiles & auto-submits', (
      tester,
    ) async {
      List<String>? submitted;
      const challenge = ArenaChallenge(
        mechanic: ArenaMechanicType.sentenceBuild,
        id: 'SB_T1',
        prompt: 'Arrange the words',
        correctAnswer: 'Cats sleep well',
        shuffledWords: ['well', 'Cats', 'sleep'],
        wordCount: 3,
        explanation: 'Simple sentence.',
      );

      await tester.pumpWidget(
        _wrap(
          ArenaSentenceBuildMechanic(
            challenge: challenge,
            state: baseState,
            isDark: false,
            isMidnight: false,
            borderColor: AppColors.slate200,
            textPrimary: AppColors.slate900,
            textSecondary: AppColors.slate500,
            onSubmitSentence: (w) => submitted = w,
          ),
        ),
      );

      for (final word in ['Cats', 'sleep', 'well']) {
        await tester.tap(find.text(word).last);
        await tester.pump();
      }
      expect(submitted, ['Cats', 'sleep', 'well']);
    });

    testWidgets('ArenaSpotErrorMechanic taps wrong word index', (
      tester,
    ) async {
      int? tappedIdx;
      const challenge = ArenaChallenge(
        mechanic: ArenaMechanicType.spotError,
        id: 'SE_T1',
        prompt: 'Tap the WRONG word',
        correctAnswer: 'less',
        sentenceTokens: ['I', 'have', 'less', 'books'],
        errorTokenIndex: 2,
        errorToken: 'less',
        correctedToken: 'fewer',
        explanation: 'Use fewer for countable nouns.',
      );

      await tester.pumpWidget(
        _wrap(
          ArenaSpotErrorMechanic(
            challenge: challenge,
            state: baseState,
            isDark: false,
            isMidnight: false,
            borderColor: AppColors.slate200,
            textPrimary: AppColors.slate900,
            textSecondary: AppColors.slate500,
            onTapToken: (idx) => tappedIdx = idx,
          ),
        ),
      );

      await tester.tap(find.text('less'));
      await tester.pump();
      expect(tappedIdx, 2);
    });

    testWidgets('ArenaMcqMechanic reuses hero & fires onSelectOption', (
      tester,
    ) async {
      int? chosen;
      const challenge = ArenaChallenge(
        mechanic: ArenaMechanicType.mcq,
        id: 'MCQ_T1',
        prompt: 'Select synonym of "FAST":',
        correctAnswer: 'Quick',
        options: ['Slow', 'Quick', 'Calm', 'Weak'],
        correctIndex: 1,
        discipline: 'word_clash',
        explanation: 'Quick means fast.',
      );

      await tester.pumpWidget(
        _wrap(
          ArenaMcqMechanic(
            challenge: challenge,
            state: baseState,
            isDark: false,
            isMidnight: false,
            borderColor: AppColors.slate200,
            textPrimary: AppColors.slate900,
            textSecondary: AppColors.slate500,
            onSelectOption: (idx) => chosen = idx,
          ),
        ),
      );

      expect(find.text('FAST'), findsOneWidget);
      await tester.tap(find.text('Quick'));
      await tester.pump();
      expect(chosen, 1);
    });

    testWidgets('ArenaSpeedSpellMechanic auto-advances OTP boxes & auto-submits', (
      tester,
    ) async {
      String? submitted;
      const challenge = ArenaChallenge(
        mechanic: ArenaMechanicType.speedSpell,
        id: 'SP_T1',
        prompt: 'Meaning: to make clear',
        correctAnswer: 'clarify',
        displayMask: 'cl_r_fy',
        missingLetters: ['a', 'i'],
        missingPositions: [2, 4],
        explanation: 'Clarify.',
      );

      await tester.pumpWidget(
        _wrap(
          ArenaSpeedSpellMechanic(
            challenge: challenge,
            state: baseState,
            isDark: false,
            isMidnight: false,
            borderColor: AppColors.slate200,
            textPrimary: AppColors.slate900,
            textSecondary: AppColors.slate500,
            onDraftChanged: (_) {},
            onSubmitLetters: (s) => submitted = s,
          ),
        ),
      );

      expect(find.byType(TextField), findsNWidgets(2));
      await tester.enterText(find.byType(TextField).at(0), 'a');
      await tester.enterText(find.byType(TextField).at(1), 'i');
      await tester.pump();
      expect(submitted, 'ai');
    });
  });

  group('Pentathlon Support Widgets (Announce, RoundStrip, Rank, Rematch, History)', () {
    testWidgets('ArenaRoundAnnounceCard and ArenaRoundStrip render mechanic metadata', (
      tester,
    ) async {
      const challenge = ArenaChallenge(
        mechanic: ArenaMechanicType.typeDuel,
        id: 'TD_A1',
        prompt: 'Definition',
        correctAnswer: 'word',
        explanation: 'Exp',
      );

      await tester.pumpWidget(
        _wrap(
          const Column(
            children: [
              ArenaRoundStrip(
                challenge: challenge,
                currentRound: 2,
                totalRounds: 7,
                isDark: false,
              ),
              Expanded(
                child: ArenaRoundAnnounceCard(
                  roundNumber: 2,
                  totalRounds: 7,
                  mechanic: ArenaMechanicType.typeDuel,
                  isDark: false,
                  isMidnight: false,
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('ROUND 2 OF 7'), findsOneWidget);
      expect(find.text('TYPE DUEL'), findsOneWidget);
    });

    testWidgets('ArenaRankBadge, ArenaRematchOverlay, ArenaMatchHistoryTile & ArenaResultDialog breakdown render cleanly', (
      tester,
    ) async {
      final record = ArenaMatchRecord(
        id: 'M1',
        roomCode: 'VOWL-DUEL-999999',
        opponentName: 'LexiconKing',
        opponentRank: ArenaRank.champion,
        result: 'win',
        myScore: 520,
        rivalScore: 410,
        myCorrectCount: 6,
        rivalCorrectCount: 5,
        rounds: const [
          ArenaRoundResult(
            mechanic: ArenaMechanicType.wordSnap,
            isCorrect: true,
            myTimeMs: 4000,
            myPoints: 73,
          ),
        ],
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: Column(
              children: [
                ArenaRankBadge.fromWins(duelWins: 35, compact: false),
                ArenaMatchHistoryTile(record: record, isDark: false),
                ArenaRematchOverlay(
                  requesterName: 'LexiconKing',
                  onAccept: () {},
                  onDecline: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.textContaining('CHAMPION'), findsOneWidget);
      expect(find.text('LexiconKing'), findsOneWidget);
      expect(find.text('520 vs 410'), findsOneWidget);
      expect(find.text('LexiconKing wants a rematch!'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          ArenaResultDialog(
            isWinner: true,
            myScore: 520,
            rivalScore: 410,
            myCorrectCount: 7,
            rivalCorrectCount: 5,
            myTotalTimeMs: 32000,
            rivalTotalTimeMs: 41000,
            rivalName: 'LexiconKing',
            payoutCoins: 60,
            totalRounds: 7,
            myDuelWins: 18,
            rivalDuelWins: 35,
            showConfetti: false,
            roundResults: const [
              ArenaRoundResult(
                mechanic: ArenaMechanicType.wordSnap,
                isCorrect: false,
                myTimeMs: 4000,
                myPoints: 0,
                prompt: 'Unscramble: very large',
                correctAnswer: 'enormous',
                explanation: 'Enormous means very large.',
              ),
              ArenaRoundResult(
                mechanic: ArenaMechanicType.rapidJudge,
                isCorrect: true,
                myTimeMs: 12000,
                myPoints: 50,
                rapidCorrectItems: 5,
                rapidTotalItems: 6,
              ),
            ],
            onRematch: () {},
            onClose: () {},
          ),
        ),
      );

      expect(find.text('ROUND BREAKDOWN'), findsOneWidget);
      expect(find.textContaining('7/7'), findsAtLeastNWidgets(1));

      // Tapping a round breakdown chip expands the mistake/explanation review card
      final chipFinder = find.textContaining('Word Snap');
      await tester.ensureVisible(chipFinder);
      await tester.pump();
      await tester.tap(chipFinder);
      await tester.pump();
      expect(find.text('Answer: enormous'), findsOneWidget);
      expect(find.text('Enormous means very large.'), findsOneWidget);
    });
  });
}
