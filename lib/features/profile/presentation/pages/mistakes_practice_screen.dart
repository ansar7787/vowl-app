import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:audioplayers/audioplayers.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/data/constants/quest_registry.dart';

class MistakesPracticeScreen extends StatefulWidget {
  final List<ErrorJournalEntry>? initialEntries;

  const MistakesPracticeScreen({super.key, this.initialEntries});

  @override
  State<MistakesPracticeScreen> createState() => _MistakesPracticeScreenState();
}

class _MistakesPracticeScreenState extends State<MistakesPracticeScreen> {
  final ValueNotifier<bool> _isLoading = ValueNotifier(true);
  final ValueNotifier<List<ErrorJournalEntry>> _entries = ValueNotifier([]);
  final ValueNotifier<int> _currentIndex = ValueNotifier(0);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  late String _userId;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadPracticeSession();
  }

  @override
  void dispose() {
    _isLoading.dispose();
    _entries.dispose();
    _currentIndex.dispose();
    _isAnswered.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadPracticeSession() async {
    _isLoading.value = true;
    final authState = context.read<AuthBloc>().state;
    _userId = authState.user?.id ?? 'local';

    List<ErrorJournalEntry> sessionEntries;

    if (widget.initialEntries != null && widget.initialEntries!.isNotEmpty) {
      sessionEntries = List.from(widget.initialEntries!);
      sessionEntries.shuffle();
    } else {
      final allEntries = await ErrorJournalCollector.fetch(
        userId: _userId,
        limit: 100,
      );

      allEntries.shuffle();
      sessionEntries = allEntries.take(10).toList();
    }

    if (mounted) {
      _entries.value = sessionEntries;
      _isLoading.value = false;
    }
  }

  void _submitAnswer(bool isCorrect) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;

    if (isCorrect) {
      di.sl<HapticService>().success();
      _audioPlayer
          .play(AssetSource('sounds/correct_chime.mp3'))
          .catchError((_) {});

      ErrorJournalCollector.dismiss(
        userId: _userId,
        entryId: _entries.value[_currentIndex.value].id,
      );
    } else {
      di.sl<HapticService>().error();
      _audioPlayer
          .play(AssetSource('sounds/wrong_buzz.mp3'))
          .catchError((_) {});
    }
  }

  void _nextCard() {
    if (_currentIndex.value < _entries.value.length - 1) {
      _currentIndex.value++;
      _isAnswered.value = false;
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          const MeshGradientBackground(showLetters: false),
          ValueListenableBuilder<bool>(
            valueListenable: _isLoading,
            builder: (context, isLoading, _) {
              return ValueListenableBuilder<List<ErrorJournalEntry>>(
                valueListenable: _entries,
                builder: (context, entries, _) {
                  return ValueListenableBuilder<int>(
                    valueListenable: _currentIndex,
                    builder: (context, currentIndex, _) {
                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverAppBar(
                            backgroundColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            elevation: 0,
                            pinned: true,
                            leading: IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              onPressed: () => context.pop(),
                            ),
                            title: (!isLoading && entries.isNotEmpty)
                                ? (VowlMotion.shouldReduceMotion(context)
                                      ? Text(
                                          '${currentIndex + 1} / ${entries.length}',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        )
                                      : Text(
                                              '${currentIndex + 1} / ${entries.length}',
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            )
                                            .animate(
                                              key: ValueKey(currentIndex),
                                            )
                                            .scale(
                                              duration: 200.ms,
                                              curve: Curves.easeOutBack,
                                            ))
                                : const SizedBox.shrink(),
                            centerTitle: true,
                          ),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 16.h,
                              ),
                              child: isLoading
                                  ? _buildShimmerLoading(context, isDark)
                                  : entries.isEmpty
                                  ? _buildEmptyState(context, isDark)
                                  : (VowlMotion.shouldReduceMotion(context)
                                        ? _buildFlashcard(
                                            context,
                                            entries[currentIndex],
                                            isDark,
                                          )
                                        : _buildFlashcard(
                                                context,
                                                entries[currentIndex],
                                                isDark,
                                              )
                                              .animate(
                                                key: ValueKey(
                                                  entries[currentIndex].id,
                                                ),
                                              )
                                              .slideX(begin: 0.1)
                                              .fadeIn(duration: 300.ms)),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child:
          Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 80.r,
                    color: AppColors.emerald500,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    context.tr(
                      'profile.practice_empty',
                      fallback: "No Mistakes to Practice!",
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              )
              .animate()
              .scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack)
              .fadeIn(),
    );
  }

  Widget _buildShimmerLoading(BuildContext context, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Shimmer.fromColors(
          baseColor: isDark
              ? AppColors.slate800.withValues(alpha: 0.5)
              : Colors.white54,
          highlightColor: isDark ? AppColors.slate700 : Colors.white,
          child: Container(
            width: double.infinity,
            height: 350.h,
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate800 : Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlashcard(
    BuildContext context,
    ErrorJournalEntry entry,
    bool isDark,
  ) {
    String wrongAnswer = entry.userAnswer.trim();
    String correctAnswer = entry.correctAnswer.trim();

    final isVisualOrInteractive = correctAnswer.isEmpty;

    if (wrongAnswer.isEmpty ||
        wrongAnswer.toLowerCase() == correctAnswer.toLowerCase()) {
      wrongAnswer = context.tr(
        'practice.timeout_answer',
        fallback: '(No Answer / Timeout)',
      );
    }

    final options = {wrongAnswer, correctAnswer}.toList();
    final random = Random(entry.id.hashCode);
    options.shuffle(random);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlassTile(
          borderRadius: BorderRadius.circular(24.r),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  entry.gameType.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.indigo500,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                entry.question,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 32.h),

              if (isVisualOrInteractive)
                Column(
                  children: [
                    Icon(
                      Icons.extension_rounded,
                      size: 48.r,
                      color: AppColors.indigo500.withValues(alpha: 0.5),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      context.tr(
                        'practice.interactive_puzzle',
                        fallback: 'Interactive Puzzle',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isAnswered,
                      builder: (context, isAnswered, _) {
                        return ElevatedButton.icon(
                          onPressed: isAnswered
                              ? null
                              : () async {
                                  final category =
                                      QuestRegistry.gameToCategory[entry
                                          .gameType] ??
                                      'reading';
                                  final uri = Uri(
                                    path: '/game',
                                    queryParameters: {
                                      'category': category,
                                      'subtype': entry.gameType,
                                      'level': entry.level.toString(),
                                    },
                                  );
                                  // Launch the actual game
                                  await context.push(uri.toString());
                                  // When they return, we assume they practiced it and mark it as correct
                                  _submitAnswer(true);
                                },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            context.tr(
                              'practice.play_level',
                              fallback: 'Play Original Level',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.indigo500,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 56.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            elevation: 0,
                          ),
                        );
                      },
                    ),
                  ],
                )
              else
                ValueListenableBuilder<bool>(
                  valueListenable: _isAnswered,
                  builder: (context, isAnswered, _) {
                    return Column(
                      children: options.map((text) {
                        final isCorrectOption = text == correctAnswer;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildOptionButton(
                            text,
                            isCorrectOption,
                            isAnswered,
                            isDark,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        ),

        ValueListenableBuilder<bool>(
          valueListenable: _isAnswered,
          builder: (context, isAnswered, _) {
            if (!isAnswered) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.only(top: 24.h),
              child: ElevatedButton(
                onPressed: _nextCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  _currentIndex.value == _entries.value.length - 1
                      ? context.tr('common.finish', fallback: 'FINISH')
                      : context.tr('common.next', fallback: 'NEXT'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ).animate().slideY(begin: 0.5).fadeIn(duration: 300.ms),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOptionButton(
    String text,
    bool isCorrectOption,
    bool isAnswered,
    bool isDark,
  ) {
    Color bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    Color borderColor = Colors.transparent;
    Color textColor = isDark ? Colors.white : Colors.black;

    if (isAnswered) {
      if (isCorrectOption) {
        bgColor = AppColors.emerald500.withValues(alpha: 0.15);
        borderColor = AppColors.emerald500;
        textColor = AppColors.emerald500;
      } else {
        bgColor = isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.02);
        textColor = isDark ? Colors.white38 : Colors.black38;
      }
    }

    return ScaleButton(
      onTap: isAnswered ? null : () => _submitAnswer(isCorrectOption),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
