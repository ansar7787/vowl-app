import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/utils/widgets/translate_button_widget.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/themes/vocab_level_theme.dart';

/// Header row: progress + lives, briefing info button, conditional hint button.
///
/// [SoundService] is resolved once in [initState] — not on every [build] call.
class VocabularyHeader extends StatefulWidget {
  final VocabularyState state;
  final int level;
  final double progress;
  final int lives;
  final VocabLevelTheme theme;
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
  State<VocabularyHeader> createState() => _VocabularyHeaderState();
}

class _VocabularyHeaderState extends State<VocabularyHeader> {
  late final SoundService _soundService;

  @override
  void initState() {
    super.initState();
    _soundService = di.sl<SoundService>();
  }

  @override
  Widget build(BuildContext context) {
    final hintShouldGlow = widget.lives < 3 && !widget.isAnswered;
    final loadedState = widget.state is VocabularyLoaded
        ? widget.state as VocabularyLoaded
        : null;
    final currentQuest = loadedState?.currentQuestOrNull;
    final hintUsed = loadedState?.hintUsed ?? false;
    final primaryColor = widget.theme.primaryColor;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          // ── Progress + lives ──────────────────────────────────────────
          Expanded(
            child: GameProgressHeader(
              level: widget.level,
              progress: widget.progress,
              lives: widget.lives,
              theme: widget.theme.source,
              isDark: widget.isDark,
              onBack: widget.onExit,
            ),
          ),

          // ── Briefing info button ──────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: ScaleButton(
              onTap: widget.onBriefingShow,
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

          // ── Hint button ───────────────────────────────────────────────
          if (currentQuest != null && !widget.isAnswered)
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: _buildHintButton(
                hintUsed: hintUsed,
                hintShouldGlow: hintShouldGlow,
                primaryColor: primaryColor,
                currentQuest: currentQuest,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHintButton({
    required bool hintUsed,
    required bool hintShouldGlow,
    required Color primaryColor,
    required VocabularyQuest currentQuest,
  }) {
    final button = QuestHintButton(
      used: hintUsed,
      primaryColor: primaryColor,
      hintText: (widget.gameType == GameSubtype.topicVocab || widget.gameType == GameSubtype.flashcards)
          ? null
          : currentQuest.hint,
      soundService: _soundService,
      onTap: () {
        context.read<VocabularyBloc>().add(const VocabularyHintUsed());
        context.read<EconomyBloc>().add(const EconomyConsumeHintRequested());
        widget.onHint();
      },
    );

    Widget animatedButton = button;
    if (hintShouldGlow) {
      animatedButton = button
          .animate(
            key: ValueKey<bool>(hintShouldGlow),
            onPlay: (c) => c.repeat(reverse: true),
          )
          .shimmer(
            color: Colors.white.withValues(alpha: 0.5),
            duration: 1.seconds,
          )
          .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        animatedButton,
        if (currentQuest.hint != null &&
            widget.gameType != GameSubtype.topicVocab &&
            hintUsed) ...[
          SizedBox(width: 8.w),
          TranslateButtonWidget(
            originalText: currentQuest.hint!,
            onTranslationComplete: (translated) {
              CustomSnackBar.show(
                context: context,
                message: translated,
                type: CustomSnackBarType.info,
                duration: const Duration(seconds: 8),
              );
            },
          ),
        ],
      ],
    );
  }
}
