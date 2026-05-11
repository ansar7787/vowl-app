import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';

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

  String get _sequenceTitle {
    switch (widget.sequenceId) {
      case 'daily_duo':
        return 'Daily Duo';
      case 'speed_blitz':
        return 'Speed Blitz';
      case 'grammar_pro':
        return 'Grammar Pro';
      default:
        return 'Themed Quest';
    }
  }

  Future<void> _startNextGame() async {
    if (_currentIndex >= widget.quests.length) {
      _finishSequence();
      return;
    }

    setState(() => _isLaunching = true);
    final quest = widget.quests[_currentIndex];

    // Derive category from subtype if type is missing as a separate field
    // Subtypes are grouped in ranges (0-9: speaking, 10-19: listening, etc.)
    final subtype = quest.subtype?.name ?? '';
    // Use the subtype's built-in category mapping instead of fragile index ranges
    String category = quest.subtype != null ? quest.subtype!.category.name : (quest.type?.name ?? 'speaking');

    final level = quest.difficulty;

    final route = '/game?category=$category&subtype=$subtype&level=$level';

    final result = await context.push(route);

    if (mounted) {
      setState(() => _isLaunching = false);
      if (result == true) {
        setState(() => _currentIndex++);
        if (_currentIndex < widget.quests.length) {
          _startNextGame();
        } else {
          _finishSequence();
        }
      } else {
        GameDialogHelper.showPremiumSnackBar(
          context,
          'Quest part cancelled. You can try again or exit.',
          icon: Icons.info_outline_rounded,
          color: Colors.orange,
        );
      }
    }
  }

  void _finishSequence() {
    GameDialogHelper.showCompletion(
      context,
      xp: 0, // Sequence doesn't track total cumulative XP yet
      coins: 0,
      title: 'QUEST COMPLETED!',
      description: 'You finished the $_sequenceTitle! Great work on your training.',
      buttonText: 'FINISH',
      popResult: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = widget.quests.isEmpty
        ? 1.0
        : _currentIndex / widget.quests.length;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F172A) 
          : Colors.white,
      body: Stack(
        children: [
          const MeshGradientBackground(showLetters: false),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 24.w),
              child: Column(
                children: [
                  Row(
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
                          children: [
                            Text(
                              _sequenceTitle.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                            Text(
                              'Part ${_currentIndex + 1} of ${widget.quests.length}',
                              style: GoogleFonts.outfit(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12.h,
                      backgroundColor: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const Spacer(),
                  GlassTile(
                    padding: EdgeInsets.all(32.r),
                    borderRadius: BorderRadius.circular(32.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentIndex < widget.quests.length
                              ? widget.quests[_currentIndex].iconData
                              : Icons.check_circle_rounded,
                          size: 64.r,
                          color: const Color(0xFF2563EB),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          _currentIndex < widget.quests.length
                              ? 'UP NEXT'
                              : 'SUMMARY',
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _currentIndex < widget.quests.length
                              ? widget.quests[_currentIndex].instruction
                              : 'All parts completed!',
                          style: GoogleFonts.outfit(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 32.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: EdgeInsets.symmetric(vertical: 20.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                            ),
                            onPressed: _isLaunching ? null : _startNextGame,
                            child: Text(
                              _isLaunching
                                  ? 'LOADING...'
                                  : 'START PART ${_currentIndex + 1}',
                              style: GoogleFonts.outfit(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

extension on GameQuest {
  IconData get iconData {
    if (subtype == null) return Icons.auto_awesome_rounded;
    final type = subtype!.category;
    switch (type) {
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
