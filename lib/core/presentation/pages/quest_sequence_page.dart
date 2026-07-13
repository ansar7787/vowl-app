import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Presents a themed multi-part quest sequence, stepping through each part
/// in order and showing aggregate progress.
///
/// Navigation: each sub-game is pushed via [GoRouter]. A `true` result
/// indicates success; anything else is treated as cancellation.
class QuestSequencePage extends StatefulWidget {
  final String sequenceId;
  final List<GameQuest> quests;

  const QuestSequencePage({
    super.key,
    required this.sequenceId,
    required this.quests,
  });

  @override
  State<QuestSequencePage> createState() => _QuestSequencePageState();
}

class _QuestSequencePageState extends State<QuestSequencePage> {
  int _currentIndex = 0;
  bool _isLaunching = false;

  // ── Computed properties ───────────────────────────────────────────────────

  String get _sequenceTitle {
    switch (widget.sequenceId) {
      case 'daily_duo':
        return context.tr('home.discovery_dailyduo_title', fallback: 'Daily Duo');
      case 'speed_blitz':
        return context.tr('home.discovery_speedblitz_title', fallback: 'Speed Blitz');
      case 'grammar_pro':
        return context.tr('home.discovery_grammarpro_title', fallback: 'Grammar Pro');
      default:
        return context.tr('home.discovery_default_title', fallback: 'Quest Sequence');
    }
  }

  bool get _isFinished => _currentIndex >= widget.quests.length;

  double get _progress => widget.quests.isEmpty
      ? 1.0
      : (_currentIndex / widget.quests.length).clamp(0.0, 1.0);

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _startNextGame() async {
    if (_isFinished) {
      _finishSequence();
      return;
    }

    if (!mounted) return;
    setState(() => _isLaunching = true);

    final quest = widget.quests[_currentIndex];
    final subtype = quest.subtype?.name ?? '';
    final category = quest.subtype != null
        ? quest.subtype!.category.name
        : (quest.type?.name ?? 'speaking');
    final level = quest.difficulty;
    final route = '/game?category=$category&subtype=$subtype&level=$level';

    Object? result;
    try {
      result = await context.push(route);
    } catch (_) {
      // Navigation failure treated as cancellation.
    }

    if (!mounted) return;
    setState(() => _isLaunching = false);

    if (result == true) {
      setState(() => _currentIndex++);
      if (_currentIndex < widget.quests.length) {
        // CRITICAL FIX: Schedule the next navigation after the current frame
        // completes to avoid calling setState + push inside the same frame,
        // which can corrupt the Navigator stack.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startNextGame();
        });
      } else {
        _finishSequence();
      }
    } else {
      GameDialogHelper.showPremiumSnackBar(
        context,
        context.tr('quest_sequence.part_cancelled', fallback: 'Part Cancelled'),
        icon: Icons.info_outline_rounded,
        color: Colors.orange,
      );
    }
  }

  void _finishSequence() {
    GameDialogHelper.showCompletion(
      context,
      xp: 0,
      coins: 0,
      title: context.tr('quest_sequence.completed_title', fallback: 'Sequence Completed!'),
      description: context.tr(
        'quest_sequence.completed_description', fallback: 'You have successfully completed all parts.',
        args: [_sequenceTitle],
      ),
      buttonText: context.tr('quest_sequence.finish_button', fallback: 'Finish'),
      popResult: true,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Stack(
        children: [
          const MeshGradientBackground(showLetters: false),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 24.w),
              child: Column(
                children: [
                  _Header(
                    isDark: isDark,
                    sequenceTitle: _sequenceTitle,
                    currentIndex: _currentIndex,
                    totalQuests: widget.quests.length,
                    progress: _progress,
                  ),
                  SizedBox(height: 32.h),
                  _ProgressBar(isDark: isDark, progress: _progress),
                  const Spacer(),
                  _QuestCard(
                    isDark: isDark,
                    isFinished: _isFinished,
                    isLaunching: _isLaunching,
                    currentIndex: _currentIndex,
                    quests: widget.quests,
                    onAction: _isLaunching ? null : _startNextGame,
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final bool isDark;
  final String sequenceTitle;
  final int currentIndex;
  final int totalQuests;
  final double progress;

  const _Header({
    required this.isDark,
    required this.sequenceTitle,
    required this.currentIndex,
    required this.totalQuests,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = currentIndex >= totalQuests;
    return Row(
      children: [
        ScaleButton(
          onTap: () => context.pop(),
          child: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close_rounded,
              size: 24.r,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sequenceTitle.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: const Color(0xFF6366F1),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                isCompleted
                    ? context.tr('quest_sequence.status_completed', fallback: 'Completed')
                    : context.tr(
                        'quest_sequence.status_part', fallback: 'Part',
                        args: ['${currentIndex + 1}', '$totalQuests'],
                      ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final bool isDark;
  final double progress;

  const _ProgressBar({required this.isDark, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr(
        'quest_sequence.progress_label', fallback: 'Progress',
        args: ['${(progress * 100).round()}'],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 12.h,
          backgroundColor: isDark
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.05),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final bool isDark;
  final bool isFinished;
  final bool isLaunching;
  final int currentIndex;
  final List<GameQuest> quests;
  final VoidCallback? onAction;

  const _QuestCard({
    required this.isDark,
    required this.isFinished,
    required this.isLaunching,
    required this.currentIndex,
    required this.quests,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final quest = !isFinished ? quests[currentIndex] : null;

    return GlassTile(
      padding: EdgeInsets.all(32.r),
      borderRadius: BorderRadius.circular(32.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFinished ? Icons.check_circle_rounded : quest!.questIconData,
            size: 64.r,
            color: const Color(0xFF6366F1),
          ),
          SizedBox(height: 24.h),
          Text(
            isFinished
                ? context.tr('quest_sequence.card_summary', fallback: 'Summary')
                : context.tr('quest_sequence.card_up_next', fallback: 'Up Next'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: const Color(0xFF6366F1),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            isFinished
                ? context.tr('quest_sequence.all_parts_done', fallback: 'All Done')
                // BUG FIX: `quest.instruction` holds a *localization key*
                // (e.g. 'quest_sequences.strengthen_weak_spots'), not
                // literal display text - see discovery_helper.dart's class
                // doc comment, which explicitly assigns this presentation
                // layer the responsibility of calling `context.tr(quest.
                // instruction)`. This call site was displaying the raw key
                // string directly, so every quest-sequence card showed
                // literal untranslated keys instead of instructions, in
                // every locale including English.
                : context.tr(quest!.instruction),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            child: ScaleButton(
              onTap: onAction,
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 20.h),
                decoration: BoxDecoration(
                  color: onAction == null
                      ? const Color(0xFF6366F1).withValues(alpha: 0.5)
                      : const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  isLaunching
                      ? context.tr('common.loading', fallback: 'Loading...').toUpperCase()
                      : isFinished
                      ? context.tr('quest_sequence.finish_button', fallback: 'Finish').toUpperCase()
                      : context.tr(
                          'quest_sequence.start_part_button', fallback: 'Start Part',
                          args: ['${currentIndex + 1}'],
                        ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GameQuest icon extension
// Kept in this file since QuestSequencePage is the only consumer.
// ---------------------------------------------------------------------------

extension _QuestIconExtension on GameQuest {
  IconData get questIconData {
    if (subtype == null) return Icons.auto_awesome_rounded;
    switch (subtype!.category) {
      case QuestType.speaking:
        return Icons.mic_rounded;
      case QuestType.listening:
        return Icons.hearing_rounded;
      case QuestType.reading:
        return Icons.menu_book_rounded;
      case QuestType.writing:
        return Icons.edit_note_rounded;
      case QuestType.grammar:
        return Icons.extension_rounded;
      case QuestType.vocabulary:
        return Icons.abc_rounded;
      case QuestType.accent:
        return Icons.record_voice_over_rounded;
      case QuestType.roleplay:
        return Icons.forum_rounded;
      case QuestType.eliteMastery:
        return Icons.workspace_premium_rounded;
    }
  }
}
