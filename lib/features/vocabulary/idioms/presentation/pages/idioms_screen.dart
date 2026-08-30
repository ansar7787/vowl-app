import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import 'package:vowl/features/vocabulary/idioms/presentation/widgets/idioms_painters.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/widgets/idioms_chat_bubbles.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/widgets/idioms_option_chip.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/widgets/idioms_origin_card.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

class IdiomsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const IdiomsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.idioms,
  });

  @override
  State<IdiomsScreen> createState() => _IdiomsScreenState();
}

class _IdiomsScreenState extends State<IdiomsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);
  final ValueNotifier<String?> _selectedOption = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  @override
  void dispose() {
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _isFirstStagePassed.dispose();
    _selectedOption.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _submitAnswer(String selected, String correct) {
    if (_isAnswered.value) return;
    _selectedOption.value = selected;
    _isAnswered.value = true;

    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    Future.delayed(600.ms, () {
      if (!mounted) return;
      if (isCorrect) {
        _hapticService.success();
        _isFirstStagePassed.value = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            );
          }
        });
      } else {
        _hapticService.error();
        _soundService.playWrong();
        _isCorrect.value = false;
        context.read<VocabularyBloc>().add(SubmitAnswer(false));
      }
    });
  }

  void _submitFinalAnswer(bool nailedIt, {String? wrongWord}) {
    if (_isAnswered.value && _isCorrect.value != null) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;
    if (wrongWord != null && wrongWord.isNotEmpty) {
      _selectedOption.value = wrongWord;
    }

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;

          if (isNewQuestion || isRetry) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
              );
            }
            _lastQuest = state.currentQuest;
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isFirstStagePassed.value = false;
            _selectedOption.value = null;
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
        }
        if (state is VocabularyGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'EMOJI EXPERT!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );
        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;

        if (state is VocabularyLoading ||
            (quest == null &&
                state is! VocabularyGameComplete &&
                state is! VocabularyError)) {
          return Scaffold(
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _isFirstStagePassed, _selectedOption]),
          builder: (context, _) {
            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value && (_isCorrect.value != null || !_isFirstStagePassed.value),
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
              onContinue: () {
                final currentState = context.read<VocabularyBloc>().state;
                if (currentState is VocabularyLoaded &&
                    !currentState.isFinalFailure &&
                    _isCorrect.value == false) {
                  _isAnswered.value = false;
                  _isCorrect.value = null;
                  _isFirstStagePassed.value = false;
                  _selectedOption.value = null;
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  }
                } else {
                  context.read<VocabularyBloc>().add(NextQuestion());
                }
              },
              onHint: () =>
                  context.read<VocabularyBloc>().add(VocabularyHintUsed()),
              useScrolling: false,
              disablePadding: true,
          child: quest == null
              ? const SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        CustomScrollView(
                          controller: _scrollController,
                          physics: (!_isFirstStagePassed.value) ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: Stack(
                            children: [
                              Positioned.fill(
                            child: CustomPaint(
                              painter: GridPainter(
                                theme.primaryColor.withValues(
                                  alpha: isDarkMode ? 0.05 : 0.03,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              SizedBox(
                                height: constraints.maxHeight,
                                child: _buildChatInterface(quest, theme.primaryColor, isDarkMode),
                              ),
                              if (_isFirstStagePassed.value)
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                                  child: Column(
                                    children: [
                                      if ((quest.origin != null && quest.origin!.isNotEmpty) || quest.literalVsFigurative != null || quest.contextSentence != null || quest.example != null)
                                        IdiomsOriginCard(
                                          origin: quest.origin,
                                          literalVsFigurative: quest.literalVsFigurative,
                                          contextSentence: quest.contextSentence ?? quest.example,
                                          color: theme.primaryColor,
                                        ),
                                    ],
                                  ),
                                ),
                              SizedBox(height: (_isAnswered.value || _isFirstStagePassed.value) ? 450.h : 60.h),
                            ],
                          ),
                        ],
                      ),
                      ),
                    ),
                  ],
                ),
                if (_isFirstStagePassed.value && (!_isAnswered.value || _isCorrect.value == null))
                  SpeakToConfirmOverlay(
                    expectedText: quest.correctAnswer ?? '',
                    primaryColor: theme.primaryColor,
                    onConfirmed: () => _submitFinalAnswer(true),
                    onSkipped: () => _submitFinalAnswer(false),
                    isPositioned: true,
                  ),
              ],
            );
          },
        ),
      );
    },
  );
},
    );
  }

  Widget _buildChatInterface(VocabularyQuest quest, Color color, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final isCompact = maxHeight < 580;

        final double estimatedContentHeight =
            (isCompact ? 30.h : 40.h) +
            (isCompact ? 40.h : 60.h) +
            (isCompact ? 100.h : 180.h) +
            (isCompact ? 20.h : 40.h);
        final remainingHeight = maxHeight - estimatedContentHeight;

        final double gapUnit = remainingHeight > 0 ? remainingHeight / 5 : 0;
        final double gapTop = remainingHeight > 0
            ? (gapUnit * 1).clamp(10.0, 30.0)
            : 10.0;
        final double gapMiddle = remainingHeight > 0
            ? (gapUnit * 1.5).clamp(10.0, 24.0)
            : 10.0;
        final double gapBottom = remainingHeight > 0
            ? (gapUnit * 2.5).clamp(15.0, 40.0)
            : 15.0;

        return Column(
              children: [
                SizedBox(height: gapTop),
                isCompact
                    ? SizedBox(
                        height: 30.h,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _buildHeaderBadge(color),
                        ),
                      )
                    : _buildHeaderBadge(color),

                SizedBox(height: gapMiddle),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 5.h,
                    ),
                    children: [
                      IdiomsSystemMessage(
                        text: "INCOMING TRANSMISSION...",
                        color: color,
                      ),
                      SizedBox(height: isCompact ? 10.h : 20.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: isCompact ? 14.r : 18.r,
                            backgroundColor: color.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.psychology_alt_rounded,
                              size: isCompact ? 16.r : 20.r,
                              color: color,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          IdiomsStrangerMessage(
                            emojis: quest.topicEmoji ?? "❓",
                            color: color,
                            isDark: isDark,
                          ),
                        ],
                      ),

                      if (_selectedOption.value != null) ...[
                        SizedBox(height: isCompact ? 14.h : 24.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IdiomsUserMessage(
                              text: _selectedOption.value!,
                              color: color,
                              isCorrect: _isCorrect.value,
                              isDark: isDark,
                            ),
                            SizedBox(width: 10.w),
                            CircleAvatar(
                              radius: isCompact ? 14.r : 18.r,
                              backgroundColor: color.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.face_retouching_natural_rounded,
                                size: isCompact ? 16.r : 20.r,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (_isAnswered.value && _isCorrect.value == false) ...[
                        SizedBox(height: 10.h),
                        IdiomsSystemMessage(
                          text: "DECRYPTION FAILED. RE-EVALUATE SEQUENCE.",
                          color: Colors.redAccent,
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: gapMiddle),

                Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Wrap(
                        spacing: 12.w,
                        runSpacing: isCompact ? 8.h : 12.h,
                        alignment: WrapAlignment.center,
                        children: (quest.options ?? []).map((o) {
                          return IdiomsOptionChip(
                            text: o,
                            correct: quest.correctAnswer ?? "",
                            color: color,
                            isDark: isDark,
                            isAnswered: _isAnswered.value,
                            isCorrect: _isCorrect.value,
                            selectedOption: _selectedOption.value,
                            onTap: () =>
                                _submitAnswer(o, quest.correctAnswer ?? ""),
                          );
                        }).toList(),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 800.ms)
                    .slideY(begin: 0.3, curve: Curves.easeOutCubic),
                SizedBox(height: gapBottom),
              ],
            );
      },
    );
  }

  Widget _buildHeaderBadge(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 8.r,
            height: 8.r,
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
          SizedBox(width: 10.w),
          Text(
            "EMOJIFY: SECURE CHANNEL",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              color: color,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Icon(Icons.lock_outline_rounded, size: 14.r, color: color),
        ],
      ),
    );
  }
}
