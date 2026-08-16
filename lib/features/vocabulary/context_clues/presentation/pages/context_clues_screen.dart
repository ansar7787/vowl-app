import 'dart:ui';
import 'dart:math' as math;
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

import 'package:vowl/core/presentation/widgets/dynamic_anagram_wrapper.dart';

// Extracted Optimized Widgets
import '../widgets/context_clues_case_header.dart';
import '../widgets/context_clues_case_file_background.dart';
import '../widgets/context_clues_evidence_sentence.dart';
import '../widgets/context_clues_scanner.dart';
import '../widgets/context_clues_evidence_tags.dart';

class ContextCluesScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ContextCluesScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.contextClues,
  });

  @override
  State<ContextCluesScreen> createState() => _ContextCluesScreenState();
}

class _ContextCluesScreenState extends State<ContextCluesScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<Offset> _lensPosition = ValueNotifier(Offset.zero);
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  bool _isFirstStagePassed = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _lensPosition.dispose();
    super.dispose();
  }

  void _onLensMove(DragUpdateDetails details, BoxConstraints constraints) {
    if (_isAnswered) return;

    final double halfWidth = constraints.maxWidth / 2;
    final double halfHeight = constraints.maxHeight / 2;
    final double padding = 90.r;

    final double maxX = math.max(0.0, halfWidth - padding);
    final double maxY = math.max(0.0, halfHeight - padding);

    // Keep lens safely inside Paper dossier boundaries
    double newX = (_lensPosition.value.dx + details.delta.dx).clamp(-maxX, maxX);
    double newY = (_lensPosition.value.dy + details.delta.dy).clamp(-maxY, maxY);

    _lensPosition.value = Offset(newX, newY);

    // Simulate finding a clue
    if (_lensPosition.value.distance % 40 < 5) {
      _hapticService.selection();
    }
  }

  void _submitAnswer(String selected, String correct) {
    if (_isAnswered || _isFirstStagePassed) return;

    setState(() {
      _selectedOption = selected;
    });

    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.selection(); // Subtle feedback for Phase 1
      setState(() {
        _isFirstStagePassed = true;
      });
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool nailedIt) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });

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
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;

          if (isNewQuestion || isRetry) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedOption = null;
              _isFirstStagePassed = false;
              _lensPosition.value = Offset.zero;
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'FORENSIC ANALYSIS COMPLETE!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

        if (state is VocabularyLoading ||
            (state is! VocabularyGameComplete &&
                _lastQuest == null &&
                state is! VocabularyLoaded &&
                state is! VocabularyError)) {
          return Scaffold(
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () {
            final currentState = context.read<VocabularyBloc>().state;
            if (currentState is VocabularyLoaded &&
                !currentState.isFinalFailure &&
                _isCorrect == false) {
              setState(() {
                _isAnswered = false;
                _isCorrect = null;
                _selectedOption = null;
              });
            } else {
              context.read<VocabularyBloc>().add(NextQuestion());
            }
          },
          onHint: () =>
              context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          useScrolling: false,
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    _buildForensicScene(
                      quest,
                      theme.primaryColor,
                      (state is VocabularyLoaded)
                          ? state.isFinalFailure
                          : false,
                    ),
                    if (_isFirstStagePassed && !_isAnswered)
                      DynamicAnagramWrapper(
                        expectedText: quest.correctAnswer ?? '',
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true),
                        onFailed: () => _submitFinalAnswer(false),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildForensicScene(
    VocabularyQuest quest,
    Color color,
    bool isFinalFailure,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final isCompact = maxHeight < 580;

        final double estimatedContentHeight =
            (isCompact ? 40.h : 60.h) +
            (isCompact ? 10.h : 20.h) +
            (isCompact ? 90.h : 110.h) +
            30.h;
        final remainingHeight = maxHeight - estimatedContentHeight;

        final double gapUnit = remainingHeight > 0 ? remainingHeight / 5 : 0;
        final double gapTop = remainingHeight > 0
            ? (gapUnit * 1).clamp(4.0, 12.0)
            : 4.0;
        final double gapMiddle = remainingHeight > 0
            ? (gapUnit * 1.5).clamp(8.0, 20.0)
            : 8.0;
        final double gapBottom = remainingHeight > 0
            ? (gapUnit * 2.5).clamp(10.0, 30.0)
            : 10.0;

        return Column(
          children: [
            SizedBox(height: gapTop),
            isCompact
                ? SizedBox(
                    height: 35.h,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ContextCluesCaseHeader(
                        level: widget.level,
                        questIndex: _lastProcessedIndex,
                        color: color,
                      ),
                    ),
                  )
                : ContextCluesCaseHeader(
                    level: widget.level,
                    questIndex: _lastProcessedIndex,
                    color: color,
                  ),
            SizedBox(height: 4.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                quest.instruction.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 9.sp,
                  color: color.withValues(alpha: 0.4),
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: gapMiddle),
            Expanded(
              child: LayoutBuilder(
                builder: (context, innerConstraints) {
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned.fill(
                        child: ContextCluesCaseFileBackground(),
                      ),
                      // BLURRED BACKGROUND (The mystery)
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 5.0,
                          end: (_isAnswered || _isFirstStagePassed) ? 0.0 : 5.0,
                        ),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, blurValue, child) {
                          return ImageFiltered(
                            imageFilter: ImageFilter.blur(
                                sigmaX: blurValue, sigmaY: blurValue),
                            child: child,
                          );
                        },
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: (_isAnswered || _isFirstStagePassed) ? 1.0 : 0.4,
                          child: ContextCluesEvidenceSentence(
                            sentence: quest.sentence ?? "",
                            color: color,
                            isCompact: isCompact,
                            isAnswered: _isAnswered,
                            isCorrect: _isCorrect,
                            selectedOption: _selectedOption,
                          ),
                        ),
                      ),
                      // LENS SYSTEM (The Flashlight)
                      if (!_isAnswered && !_isFirstStagePassed)
                        ValueListenableBuilder<Offset>(
                          valueListenable: _lensPosition,
                          builder: (context, pos, _) {
                            final lensSize = isCompact ? 100.r : 160.r;
                            final lensRadius = lensSize / 2;
                            final centerPos = Offset(
                              (innerConstraints.maxWidth / 2) + pos.dx,
                              (innerConstraints.maxHeight / 2) + pos.dy,
                            );

                            return Positioned.fill(
                              child: Stack(
                                children: [
                                  // SHARP TEXT (Revealed inside the lens)
                                  Positioned.fill(
                                    child: ClipPath(
                                      clipper: CircleClipper(centerPos, lensRadius * 0.85),
                                      child: ContextCluesEvidenceSentence(
                                        sentence: quest.sentence ?? "",
                                        color: color,
                                        isCompact: isCompact,
                                        isAnswered: _isAnswered,
                                        isCorrect: _isCorrect,
                                        selectedOption: _selectedOption,
                                      ),
                                    ),
                                  ),
                                  // THE PHYSICAL LENS UI
                                  Positioned(
                                    left: centerPos.dx - lensRadius,
                                    top: centerPos.dy - lensRadius,
                                    child: GestureDetector(
                                      onPanUpdate: (d) =>
                                          _onLensMove(d, innerConstraints),
                                      child: isCompact
                                          ? SizedBox(
                                              width: lensSize,
                                              height: lensSize,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: ContextCluesScanner(
                                                  color: color,
                                                ),
                                              ),
                                            )
                                          : ContextCluesScanner(color: color),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: gapMiddle),
            ContextCluesEvidenceTags(
              options: quest.options ?? [],
              correct: quest.correctAnswer ?? "",
              color: color,
              isAnswered: _isAnswered,
              isCorrect: _isCorrect,
              selectedOption: _selectedOption,
              isFinalFailure: isFinalFailure,
              onOptionSelected: (o) =>
                  _submitAnswer(o, quest.correctAnswer ?? ""),
            ),
            SizedBox(height: gapBottom),
          ],
        );
      },
    );
  }
}

class CircleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  CircleClipper(this.center, this.radius);

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant CircleClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}

