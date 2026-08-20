import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/dynamic_jigsaw_wrapper.dart';

class JigsawPuzzleScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const JigsawPuzzleScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.jigsawPuzzle,
  });

  @override
  State<JigsawPuzzleScreen> createState() => _JigsawPuzzleScreenState();
}

class _JigsawPuzzleScreenState extends State<JigsawPuzzleScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;
  bool _pendingJigsaw = false;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onSubmit(bool nailedIt) {
    if (_isAnswered) return;

    if (nailedIt) {
      _soundService.playCorrect();
      _hapticService.success();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
        _pendingJigsaw = false;
      });
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _soundService.playWrong();
      _hapticService.error();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _pendingJigsaw = false;
      });
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = !state.answerStatus.isAnswered && _isAnswered;

          if (isNewQuestion || isRetry) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _showConfetti = false;
              _pendingJigsaw = false;
            });
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
              _pendingJigsaw = false;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr('vocabulary.jigsaw_master', fallback: 'JIGSAW MASTER!'),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);

        if (state is VocabularyLoading ||
            (state is! VocabularyGameComplete &&
                _lastQuest == null &&
                state is! VocabularyLoaded &&
                state is! VocabularyError)) {
          return Scaffold(
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () {
            // Can implement a hint system for the jigsaw pieces if needed
          },
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.all(24.r),
                          sliver: SliverToBoxAdapter(
                            child: Column(
                              children: [
                                SizedBox(height: 16.h),
                                _buildInstructionCard(theme.primaryColor, quest),
                                SizedBox(height: 40.h),
                                _buildQuestContent(theme.primaryColor, quest, Theme.of(context).brightness == Brightness.dark),
                                SizedBox(height: (_isAnswered || _pendingJigsaw) ? 160.h : 60.h),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!_isAnswered && !_pendingJigsaw)
                      Positioned(
                        bottom: 40.h,
                        left: 24.w,
                        right: 24.w,
                        child: ElevatedButton(
                          onPressed: () {
                            _hapticService.selection();
                            setState(() => _pendingJigsaw = true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                          child: Text(
                            context.tr('games.start_assembling', fallback: 'Start Assembling'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (_pendingJigsaw && !_isAnswered)
                      DynamicJigsawWrapper(
                        expectedText: quest.correctAnswer ?? '',
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _onSubmit(true),
                        onSkipped: () => _onSubmit(false),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildInstructionCard(Color primaryColor, VocabularyQuest quest) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(Icons.extension_rounded, color: primaryColor, size: 32.sp),
          SizedBox(height: 12.h),
          Text(
            quest.instruction ?? 'Assemble the pieces into meaning.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: primaryColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestContent(Color primaryColor, VocabularyQuest quest, bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            quest.word?.toUpperCase() ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 2,
            ),
          ),
          if (quest.question != null && quest.question!.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text(
              quest.question!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
