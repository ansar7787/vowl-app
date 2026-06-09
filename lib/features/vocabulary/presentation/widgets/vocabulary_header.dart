import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_header.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

class VocabularyHeader extends StatelessWidget {
  final VocabularyState state;
  final int level;
  final double progress;
  final int lives;
  final dynamic theme;
  final bool isDark;
  final bool isAnswered;
  final GameSubtype gameType;
  final VoidCallback onExit;
  final VoidCallback onBriefingShow;
  final VoidCallback onHint;

  const VocabularyHeader({
    super.key,
    required this.state,
    required this.level,
    required this.progress,
    required this.lives,
    required this.theme,
    required this.isDark,
    required this.isAnswered,
    required this.gameType,
    required this.onExit,
    required this.onBriefingShow,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    final hintShouldGlow = lives < 3 && !isAnswered;
    final currentQuest = state is VocabularyLoaded
        ? (state as VocabularyLoaded).currentQuestOrNull
        : null;
    final hintUsed = state is VocabularyLoaded
        ? (state as VocabularyLoaded).hintUsed
        : false;
    final Color primaryColor = theme.primaryColor as Color;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          // Progress + lives header
          Expanded(
            child: FlashcardHeader(
              level: level,
              progress: progress,
              lives: lives,
              streak: state is VocabularyLoaded
                  ? (state as VocabularyLoaded).currentIndex
                  : 0,
              theme: theme,
              isDark: isDark,
              onBack: onExit,
            ),
          ),

          // Info / briefing button
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: ScaleButton(
              onTap: onBriefingShow,
              child: Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 16.r,
                  color: primaryColor,
                ),
              ),
            ),
          ),

          // Hint button — only shown when quest is active
          if (currentQuest != null && !isAnswered)
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child:
                  QuestHintButton(
                        used: hintUsed,
                        primaryColor: primaryColor,
                        hintText: gameType == GameSubtype.topicVocab
                            ? null
                            : currentQuest.hint,
                        soundService: di.sl<SoundService>(),
                        onTap: () {
                          context.read<VocabularyBloc>().add(
                            const VocabularyHintUsed(),
                          );
                          context.read<EconomyBloc>().add(
                            const EconomyConsumeHintRequested(),
                          );
                          onHint();
                        },
                      )
                      .animate(
                        target: hintShouldGlow ? 1 : 0,
                        onPlay: (c) => c.repeat(reverse: true),
                      )
                      .shimmer(
                        color: Colors.white.withValues(alpha: 0.5),
                        duration: 1.seconds,
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                      ),
            ),
        ],
      ),
    );
  }
}
