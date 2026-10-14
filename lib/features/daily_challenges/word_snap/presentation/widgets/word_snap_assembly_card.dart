import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/daily_challenges/word_snap/domain/models/word_snap_puzzle.dart';

/// Single item representing a word tile in the Word Snap assembly board.
class _SnapTileItem {
  final int id;
  final String text;

  const _SnapTileItem({required this.id, required this.text});
}

/// Bespoke sentence assembly board designed specifically for Word Snap.
///
/// Features:
/// - Tactile word placement and removal with immediate haptic response.
/// - Single primary Submit button (no skip/bypass distractions).
/// - Non-punitive learning loop: Wrong submissions highlight incorrect positions
///   and allow infinite retries without Game Over popups or life loss.
/// - Confetti and celebratory audio on correct sentence completion.
class WordSnapAssemblyCard extends StatefulWidget {
  final WordSnapPuzzle puzzle;
  final Color primaryColor;
  final VoidCallback onSuccess;
  final SoundService soundService;
  final HapticService hapticService;
  final bool isAnswered;

  const WordSnapAssemblyCard({
    super.key,
    required this.puzzle,
    required this.primaryColor,
    required this.onSuccess,
    required this.soundService,
    required this.hapticService,
    this.isAnswered = false,
  });

  @override
  State<WordSnapAssemblyCard> createState() => _WordSnapAssemblyCardState();
}

class _WordSnapAssemblyCardState extends State<WordSnapAssemblyCard>
    with SingleTickerProviderStateMixin {
  late List<_SnapTileItem> _availableTiles;
  final List<_SnapTileItem> _placedTiles = [];
  List<bool?>? _positionFeedback;
  bool _hasError = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    _initTiles();
  }

  @override
  void didUpdateWidget(WordSnapAssemblyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.puzzle.id != widget.puzzle.id ||
        oldWidget.puzzle.playableSentence != widget.puzzle.playableSentence) {
      _initTiles();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _initTiles() {
    final words = widget.puzzle.playableWords;
    final List<_SnapTileItem> items = [];
    for (int i = 0; i < words.length; i++) {
      items.add(_SnapTileItem(id: i, text: words[i]));
    }

    // Deterministic shuffle using puzzle id seed so arrangement is consistent yet scrambled
    final rand = Random(widget.puzzle.id * 31 + 7);
    items.shuffle(rand);

    // If accidental identity shuffle, rotate once
    if (_normalize(items.map((e) => e.text).join(' ')) == _normalize(widget.puzzle.playableSentence) &&
        items.length > 1) {
      final first = items.removeAt(0);
      items.add(first);
    }

    setState(() {
      _availableTiles = items;
      _placedTiles.clear();
      _positionFeedback = null;
      _hasError = false;
    });
  }

  void _onTileTap(_SnapTileItem tile) {
    if (widget.isAnswered) return;
    widget.hapticService.selection();

    setState(() {
      _availableTiles.removeWhere((t) => t.id == tile.id);
      _placedTiles.add(tile);
      _positionFeedback = null;
      _hasError = false;
    });
  }

  void _onPlacedTileTap(int index) {
    if (widget.isAnswered) return;
    widget.hapticService.selection();

    setState(() {
      final removed = _placedTiles.removeAt(index);
      _availableTiles.add(removed);
      _positionFeedback = null;
      _hasError = false;
    });
  }

  void _onClearAll() {
    if (widget.isAnswered || _placedTiles.isEmpty) return;
    widget.hapticService.light();

    setState(() {
      _availableTiles.addAll(_placedTiles);
      _placedTiles.clear();
      _positionFeedback = null;
      _hasError = false;
    });
  }

  static String _normalize(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  void _onSubmit() {
    if (widget.isAnswered || _placedTiles.length != widget.puzzle.playableWords.length) {
      return;
    }

    final assembled = _placedTiles.map((t) => t.text).join(' ');
    final target = widget.puzzle.playableSentence;

    final isCorrect = _normalize(assembled) == _normalize(target);

    if (isCorrect) {
      widget.hapticService.success();
      widget.soundService.playCorrect();
      setState(() {
        _hasError = false;
        _positionFeedback = List.filled(_placedTiles.length, true);
      });
      widget.onSuccess();
    } else {
      widget.hapticService.error();
      widget.soundService.playWrong();
      _shakeController.forward(from: 0.0);

      // Positional feedback: evaluate which words are currently in the expected position
      final expectedWords = widget.puzzle.playableWords;
      final feedback = List<bool?>.filled(_placedTiles.length, false);
      for (int i = 0; i < _placedTiles.length; i++) {
        if (i < expectedWords.length &&
            _normalize(_placedTiles[i].text) == _normalize(expectedWords[i])) {
          feedback[i] = true;
        }
      }

      setState(() {
        _hasError = true;
        _positionFeedback = feedback;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalWords = widget.puzzle.playableWords.length;
    final allPlaced = _placedTiles.length == totalWords;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Workbench Card (Assembled sentence zone) ───────────────────
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.7)
                  : Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: _hasError
                    ? AppColors.rose500.withValues(alpha: 0.6)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : widget.primaryColor.withValues(alpha: 0.2)),
                width: 1.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_hasError ? AppColors.rose500 : widget.primaryColor)
                      .withValues(alpha: isDark ? 0.15 : 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workbench Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.dashboard_customize_rounded,
                          size: 15.r,
                          color: widget.primaryColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          context.tr('games.assemble_sentence', fallback: 'Build the Sentence'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: widget.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    if (_placedTiles.isNotEmpty && !widget.isAnswered)
                      ScaleButton(
                        onTap: _onClearAll,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppColors.slate100,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 12.r,
                                color: isDark ? Colors.white70 : AppColors.slate600,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                context.tr('common.reset', fallback: 'Clear'),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : AppColors.slate600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 14.h),

                // Assembled Slots or Empty Placeholder
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: 64.h),
                  child: _placedTiles.isEmpty
                      ? Center(
                          child: Text(
                            context.tr(
                              'games.tap_words_to_snap',
                              fallback: 'Tap words below in sequence to assemble the sentence.',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white38 : AppColors.slate400,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 8.w,
                          runSpacing: 10.h,
                          children: List.generate(_placedTiles.length, (index) {
                            final tile = _placedTiles[index];
                            final isPosCorrect = _positionFeedback != null
                                ? _positionFeedback![index]
                                : null;

                            Color tileBg = isDark
                                ? widget.primaryColor.withValues(alpha: 0.22)
                                : widget.primaryColor.withValues(alpha: 0.12);
                            Color tileBorder = widget.primaryColor.withValues(alpha: 0.4);
                            Color tileText = isDark ? Colors.white : theme.colorScheme.onSurface;

                            if (isPosCorrect == true) {
                              tileBg = AppColors.emerald500.withValues(alpha: 0.2);
                              tileBorder = AppColors.emerald500.withValues(alpha: 0.6);
                            } else if (isPosCorrect == false) {
                              tileBg = AppColors.rose500.withValues(alpha: 0.18);
                              tileBorder = AppColors.rose500.withValues(alpha: 0.6);
                            }

                            return ScaleButton(
                              onTap: () => _onPlacedTileTap(index),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 9.h,
                                ),
                                decoration: BoxDecoration(
                                  color: tileBg,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: tileBorder, width: 1.5.w),
                                  boxShadow: [
                                    BoxShadow(
                                      color: tileBorder.withValues(alpha: 0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      tile.text,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: tileText,
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Icon(
                                      isPosCorrect == true
                                          ? Icons.check_circle_rounded
                                          : (isPosCorrect == false
                                              ? Icons.close_rounded
                                              : Icons.close_rounded),
                                      size: 13.r,
                                      color: isPosCorrect == true
                                          ? AppColors.emerald500
                                          : (isPosCorrect == false
                                              ? AppColors.rose500
                                              : tileText.withValues(alpha: 0.4)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                ),

                // Error Feedback Banner (Encouraging, non-punitive)
                if (_hasError) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: AppColors.rose500.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.rose500.withValues(alpha: 0.25),
                        width: 1.w,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15.r,
                          color: AppColors.rose500,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            context.tr(
                              'games.reorder_try_again',
                              fallback: 'Word order is not quite right. Tap tiles to adjust and try again!',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.rose500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 18.h),

          // ── 2. Word Bank (Available word tiles to snap) ───────────────────
          if (_availableTiles.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 14.r,
                    color: isDark ? Colors.white54 : AppColors.slate500,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    context.tr('games.word_bank', fallback: 'Word Bank'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: isDark ? Colors.white54 : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 10.h,
              alignment: WrapAlignment.center,
              children: _availableTiles.map((tile) {
                return ScaleButton(
                  onTap: () => _onTileTap(tile),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(13.r),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : AppColors.slate200,
                        width: 1.2.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      tile.text,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.slate800,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24.h),
          ] else ...[
            SizedBox(height: 12.h),
          ],

          // ── 3. Submit Button (Only button — NO SKIP) ──────────────────────
          ScaleButton(
            onTap: (allPlaced && !widget.isAnswered) ? _onSubmit : null,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: allPlaced
                    ? widget.primaryColor
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.slate200),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: allPlaced
                    ? [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  context.tr('game.check_answer', fallback: 'CHECK ANSWER'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: allPlaced
                        ? Colors.white
                        : (isDark ? Colors.white30 : AppColors.slate400),
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

