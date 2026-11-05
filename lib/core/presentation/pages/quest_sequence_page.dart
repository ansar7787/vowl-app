import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/home/presentation/widgets/discovery_deck.dart';

/// Presents a curriculum-synced multi-part quest track briefing and
/// connected interactive stepper roadmap.
///
/// Navigation: each sub-game is pushed via [GoRouter]. A `true` result
/// indicates success; anything else is treated as cancellation.
/// Level progression, XP, and coins are credited natively and legitimately
/// by the game engine and persisted directly to the user's curriculum record.
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

  late final ValueNotifier<int> _stateHash = ValueNotifier(0);

  void _updateState() {
    if (mounted) _stateHash.value++;
  }

  @override
  void dispose() {
    _stateHash.dispose();
    super.dispose();
  }

  // ── Computed properties ───────────────────────────────────────────────────

  String get _sequenceTitle {
    switch (widget.sequenceId) {
      case 'smart_recommendation':
      case 'smart_focus':
        return context.tr(
          'home.discovery_smartfocus_title',
          fallback: 'Smart Focus',
        );
      case 'daily_duo':
      case 'daily_workout':
        return context.tr(
          'home.discovery_dailyworkout_title',
          fallback: 'Daily Workout',
        );
      case 'speed_blitz':
      case 'rapid_recall':
        return context.tr(
          'home.discovery_rapidrecall_title',
          fallback: 'Rapid Recall',
        );
      case 'grammar_pro':
      case 'sentence_lab':
        return context.tr(
          'home.discovery_sentencelab_title',
          fallback: 'Sentence Lab',
        );
      default:
        return context.tr(
          'home.discovery_default_title',
          fallback: 'Themed Quest',
        );
    }
  }

  String get _sequenceBadge {
    switch (widget.sequenceId) {
      case 'smart_recommendation':
      case 'smart_focus':
        return 'ADAPTIVE AI';
      case 'daily_duo':
      case 'daily_workout':
        return 'DAILY ROUTINE';
      case 'speed_blitz':
      case 'rapid_recall':
        return 'SPEED SPRINT';
      case 'grammar_pro':
      case 'sentence_lab':
        return 'SYNTAX LAB';
      default:
        return 'THEMED TRACK';
    }
  }

  Color get _sequenceColor {
    switch (widget.sequenceId) {
      case 'smart_recommendation':
      case 'smart_focus':
        return AppColors.indigo500;
      case 'daily_duo':
      case 'daily_workout':
        return const Color(0xFF06B6D4); // Cyan
      case 'speed_blitz':
      case 'rapid_recall':
        return IllustrationColors.warmOrange;
      case 'grammar_pro':
      case 'sentence_lab':
        return AppColors.emerald500;
      default:
        return AppColors.indigo500;
    }
  }

  bool get _isFinished => _currentIndex >= widget.quests.length;

  double get _progress => widget.quests.isEmpty
      ? 1.0
      : (_currentIndex / widget.quests.length).clamp(0.0, 1.0);

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _startNextGame() async {
    if (_isLaunching) return;
    if (_isFinished) {
      _finishSequence();
      return;
    }

    if (!mounted) return;
    _isLaunching = true;
    _updateState();

    final quest = widget.quests[_currentIndex];
    final subtype = quest.subtype?.name ?? '';
    final category = quest.subtype != null
        ? quest.subtype!.category.serializedName
        : (quest.type?.serializedName ?? 'speaking');
    final level = quest.difficulty;
    final route = '/game?category=$category&subtype=$subtype&level=$level';

    Object? result;
    try {
      result = await context.push(route);
    } catch (_) {
      // Navigation failure treated as cancellation.
    }

    if (!mounted) return;
    _isLaunching = false;

    // Dual verification: route returned true OR the level was marked completed natively in AuthBloc
    final user = context.read<AuthBloc>().state.user;
    final isLevelCompletedNatively = user != null &&
        (user.completedLevels[subtype]?.contains(level) ?? false);
    final isSuccess = result == true || isLevelCompletedNatively;

    if (isSuccess) {
      _currentIndex++;
      _updateState();
      try {
        di.sl<HapticService>().selection();
      } catch (_) {}

      // Refresh AuthBloc immediately so the newly unlocked level is synced app-wide
      try {
        context.read<AuthBloc>().add(const AuthRefreshUser());
      } catch (_) {}

      if (_currentIndex >= widget.quests.length) {
        _finishSequence();
      }
    } else {
      _updateState();
      GameDialogHelper.showPremiumSnackBar(
        context,
        context.tr(
          'quest_sequence.part_cancelled',
          fallback: 'Quest part cancelled. You can try again or exit.',
        ),
        icon: Icons.info_outline_rounded,
        color: Colors.orange,
      );
    }
  }

  void _finishSequence() async {
    // Refresh user state so any completed level changes sync to the map immediately
    try {
      context.read<AuthBloc>().add(const AuthRefreshUser());
    } catch (_) {}

    // Record today's completion locally in SharedPreferences for daily practice cards
    try {
      final user = context.read<AuthBloc>().state.user;
      final userId = user?.id ?? 'guest';
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await prefs.setString(
        'vowl_sequence_completed_${widget.sequenceId}_$userId',
        todayStr,
      );
      DiscoveryDeck.notifySequenceCompleted();
    } catch (_) {}

    if (!mounted) return;

    // No artificial reward injection: individual games already credit verified
    // rewards to Firestore during gameplay. xp: 0 and coins: 0 ensures no double-awarding.
    // GameDialogHelper.showCompletion handles victory fanfare sound and haptic natively.
    GameDialogHelper.showCompletion(
      context,
      xp: 0,
      coins: 0,
      title: context.tr(
        'quest_sequence.completed_title',
        fallback: 'QUEST COMPLETED!',
      ),
      description: context.tr(
        'quest_sequence.completed_description',
        fallback: 'You finished {}! Great work on your training.',
        args: [_sequenceTitle],
      ),
      buttonText: context.tr(
        'quest_sequence.finish_button',
        fallback: 'FINISH',
      ),
      popResult: true,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    return Scaffold(
      backgroundColor: isMidnight
          ? Colors.black
          : (isDark ? AppColors.slate900 : Colors.white),
      body: Stack(
        children: [
          const MeshGradientBackground(showLetters: false),
          ValueListenableBuilder<int>(
            valueListenable: _stateHash,
            builder: (context, _, child) {
              return SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Top Track Briefing Header
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
                      child: _Header(
                        isDark: isDark,
                        badge: _sequenceBadge,
                        sequenceTitle: _sequenceTitle,
                        currentIndex: _currentIndex,
                        totalQuests: widget.quests.length,
                        accentColor: _sequenceColor,
                      ),
                    ),

                    SizedBox(height: 14.h),

                    // Sleek Rounded Progress Bar
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: _ProgressBar(
                        isDark: isDark,
                        progress: _progress,
                        color: _sequenceColor,
                      ),
                    ),

                    SizedBox(height: 14.h),

                    // Track Meta Bar (Duration + Curriculum Sync)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: _TrackBriefingMetaBar(
                        isDark: isDark,
                        totalQuests: widget.quests.length,
                        accentColor: _sequenceColor,
                      ),
                    ),

                    SizedBox(height: 14.h),

                    // Scrollable Connected Stepper Roadmap
                    Expanded(
                      child: widget.quests.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                child: _SummaryEmptyCard(
                                  isDark: isDark,
                                  onFinish: _finishSequence,
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 20.h),
                              child: Column(
                                children: List.generate(
                                  widget.quests.length,
                                  (index) {
                                    final quest = widget.quests[index];
                                    final isCompleted = index < _currentIndex;
                                    final isCurrent =
                                        index == _currentIndex && !_isFinished;
                                    final isLocked = index > _currentIndex;
                                    final isLast =
                                        index == widget.quests.length - 1;

                                    return _ConnectedStepperRow(
                                      index: index,
                                      isLast: isLast,
                                      isCompleted: isCompleted,
                                      isCurrent: isCurrent,
                                      isLocked: isLocked,
                                      quest: quest,
                                      totalQuests: widget.quests.length,
                                      isDark: isDark,
                                      accentColor: _sequenceColor,
                                      onCardTap: isCurrent
                                          ? _startNextGame
                                          : (isLocked
                                              ? () {
                                                  try {
                                                    di.sl<HapticService>().selection();
                                                  } catch (_) {}
                                                  GameDialogHelper.showPremiumSnackBar(
                                                    context,
                                                    context.tr(
                                                      'quest_sequence.complete_current_first',
                                                      fallback:
                                                          'Complete the current part to unlock this step.',
                                                    ),
                                                    icon: Icons.lock_outline_rounded,
                                                    color: AppColors.slate700,
                                                  );
                                                }
                                              : null),
                                    );
                                  },
                                ),
                              ),
                            ),
                    ),

                    // Fixed Floating Bottom Action Dock
                    if (widget.quests.isNotEmpty)
                      _BottomActionDock(
                        isDark: isDark,
                        isMidnight: isMidnight,
                        isLaunching: _isLaunching,
                        isFinished: _isFinished,
                        currentIndex: _currentIndex,
                        accentColor: _sequenceColor,
                        onAction: _isLaunching ? null : _startNextGame,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header Component
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final bool isDark;
  final String badge;
  final String sequenceTitle;
  final int currentIndex;
  final int totalQuests;
  final Color accentColor;

  const _Header({
    required this.isDark,
    required this.badge,
    required this.sequenceTitle,
    required this.currentIndex,
    required this.totalQuests,
    required this.accentColor,
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
              size: 22.r,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                sequenceTitle.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: accentColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                isCompleted
                    ? context.tr(
                        'quest_sequence.status_completed',
                        fallback: 'Completed',
                      )
                    : context.tr(
                        'quest_sequence.status_part',
                        fallback: 'Part',
                        args: ['${currentIndex + 1}', '$totalQuests'],
                      ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Progress Bar Component
// ---------------------------------------------------------------------------

class _ProgressBar extends StatelessWidget {
  final bool isDark;
  final double progress;
  final Color color;

  const _ProgressBar({
    required this.isDark,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr(
        'quest_sequence.progress_label',
        fallback: 'Progress: {} percent',
        args: ['${(progress * 100).round()}'],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 8.h,
          backgroundColor: isDark
              ? Colors.white10
              : Colors.black.withValues(alpha: 0.05),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Track Briefing Meta Bar Component
// ---------------------------------------------------------------------------

class _TrackBriefingMetaBar extends StatelessWidget {
  final bool isDark;
  final int totalQuests;
  final Color accentColor;

  const _TrackBriefingMetaBar({
    required this.isDark,
    required this.totalQuests,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final estMinutes = (totalQuests * 1.5).round().clamp(2, 8);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.slate100,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Duration chip
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 15.r,
                color: isDark ? Colors.white70 : AppColors.slate600,
              ),
              SizedBox(width: 5.w),
              Text(
                context.tr(
                  'quest_sequence.estimated_duration',
                  fallback: '~{} min',
                  args: ['$estMinutes'],
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : AppColors.slate600,
                ),
              ),
            ],
          ),

          // Curriculum synced badge
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 14.r,
                  color: accentColor,
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    'CURRICULUM SYNCED',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: accentColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Connected Stepper Row & Card
// ---------------------------------------------------------------------------

class _ConnectedStepperRow extends StatelessWidget {
  final int index;
  final bool isLast;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;
  final GameQuest quest;
  final int totalQuests;
  final bool isDark;
  final Color accentColor;
  final VoidCallback? onCardTap;

  const _ConnectedStepperRow({
    required this.index,
    required this.isLast,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
    required this.quest,
    required this.totalQuests,
    required this.isDark,
    required this.accentColor,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Node Column
          SizedBox(
            width: 32.w,
            child: Column(
              children: [
                // Node Icon
                Container(
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.emerald500
                        : (isCurrent
                            ? accentColor
                            : (isDark ? Colors.white12 : AppColors.slate200)),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      isCompleted
                          ? Icons.check_rounded
                          : (isCurrent
                              ? Icons.play_arrow_rounded
                              : Icons.lock_outline_rounded),
                      size: 16.r,
                      color: isLocked && !isDark ? AppColors.slate500 : Colors.white,
                    ),
                  ),
                ),

                // Connecting Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.w,
                      color: isCompleted
                          ? AppColors.emerald500.withValues(alpha: 0.5)
                          : (isDark ? Colors.white12 : AppColors.slate200),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(width: 12.w),

          // Step Content Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
              child: ScaleButton(
                onTap: onCardTap,
                child: Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isCurrent
                          ? accentColor.withValues(alpha: 0.7)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.slate200),
                      width: isCurrent ? 1.5.r : 1.r,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row: Category Badge + Level Pill
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: quest.categoryColor.withValues(
                                alpha: isDark ? 0.22 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  quest.questIconData,
                                  size: 12.r,
                                  color: quest.categoryColor,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  quest.categoryLabel.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: quest.categoryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : AppColors.slate100,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'LVL ${quest.difficulty}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white70 : AppColors.slate600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.star_rounded,
                            size: 14.r,
                            color: const Color(0xFFF59E0B),
                          ),
                        ],
                      ),

                      SizedBox(height: 8.h),

                      // Formatted Subtype Title
                      Text(
                        _formatSubtypeName(quest.subtype),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.slate900,
                          letterSpacing: -0.2,
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Pedagogical Instruction Focus
                      Text(
                        context.tr(quest.instruction),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          height: 1.25,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      // Status Badge Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isCompleted)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.emerald500.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                context.tr('quest_sequence.step_completed', fallback: 'COMPLETED'),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.emerald500,
                                ),
                              ),
                            )
                          else if (isCurrent)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                context.tr('quest_sequence.current_step', fallback: 'CURRENT STEP'),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : AppColors.slate100,
                              ),
                              child: Text(
                                context.tr('quest_sequence.step_locked', fallback: 'UP NEXT'),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white38 : AppColors.slate400,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
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
// Fixed Floating Bottom Action Dock
// ---------------------------------------------------------------------------

class _BottomActionDock extends StatelessWidget {
  final bool isDark;
  final bool isMidnight;
  final bool isLaunching;
  final bool isFinished;
  final int currentIndex;
  final Color accentColor;
  final VoidCallback? onAction;

  const _BottomActionDock({
    required this.isDark,
    required this.isMidnight,
    required this.isLaunching,
    required this.isFinished,
    required this.currentIndex,
    required this.accentColor,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        14.h + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: isMidnight
            ? Colors.black.withValues(alpha: 0.95)
            : (isDark
                ? AppColors.slate900.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: ScaleButton(
        debounceDuration: const Duration(milliseconds: 100),
        onTap: onAction,
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: onAction == null
                ? accentColor.withValues(alpha: 0.5)
                : accentColor,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            isLaunching
                ? context.tr('common.loading', fallback: 'Loading...').toUpperCase()
                : isFinished
                    ? context.tr('quest_sequence.finish_button', fallback: 'FINISH').toUpperCase()
                    : context.tr(
                        'quest_sequence.start_part_button',
                        fallback: 'Start Part',
                        args: ['${currentIndex + 1}'],
                      ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary Empty Card for Graceful Empty State
// ---------------------------------------------------------------------------

class _SummaryEmptyCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onFinish;

  const _SummaryEmptyCard({required this.isDark, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(28.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 64.r,
            color: AppColors.emerald500,
          ),
          SizedBox(height: 16.h),
          Text(
            context.tr('quest_sequence.card_summary', fallback: 'SUMMARY'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: AppColors.indigo500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            context.tr(
              'quest_sequence.all_parts_done',
              fallback: 'All parts completed!',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ScaleButton(
            onTap: onFinish,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: AppColors.indigo500,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(
                context.tr('quest_sequence.finish_button', fallback: 'FINISH'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
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
// Subtype Name Formatter & Quest Type Extensions
// ---------------------------------------------------------------------------

String _formatSubtypeName(GameSubtype? subtype) {
  if (subtype == null) return 'Curated Quest';
  final name = subtype.name;
  final buffer = StringBuffer();
  for (int i = 0; i < name.length; i++) {
    final char = name[i];
    if (i > 0 && char == char.toUpperCase() && name[i - 1] != ' ') {
      buffer.write(' ');
    }
    if (i == 0) {
      buffer.write(char.toUpperCase());
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

extension _QuestCategoryExtension on GameQuest {
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

  String get categoryLabel {
    final cat = subtype?.category ?? type ?? QuestType.speaking;
    switch (cat) {
      case QuestType.speaking:
        return 'Speaking';
      case QuestType.listening:
        return 'Listening';
      case QuestType.reading:
        return 'Reading';
      case QuestType.writing:
        return 'Writing';
      case QuestType.grammar:
        return 'Grammar';
      case QuestType.vocabulary:
        return 'Vocab';
      case QuestType.accent:
        return 'Accent';
      case QuestType.roleplay:
        return 'Roleplay';
      case QuestType.eliteMastery:
        return 'Elite';
    }
  }

  Color get categoryColor {
    final cat = subtype?.category ?? type ?? QuestType.speaking;
    switch (cat) {
      case QuestType.speaking:
        return const Color(0xFF6366F1); // Indigo
      case QuestType.listening:
        return const Color(0xFF06B6D4); // Cyan
      case QuestType.reading:
        return const Color(0xFF3B82F6); // Blue
      case QuestType.writing:
        return const Color(0xFF8B5CF6); // Purple
      case QuestType.grammar:
        return const Color(0xFF10B981); // Emerald
      case QuestType.vocabulary:
        return const Color(0xFFF59E0B); // Amber
      case QuestType.accent:
        return const Color(0xFFF97316); // Orange
      case QuestType.roleplay:
        return const Color(0xFFEC4899); // Pink
      case QuestType.eliteMastery:
        return const Color(0xFFEAB308); // Gold
    }
  }
}
