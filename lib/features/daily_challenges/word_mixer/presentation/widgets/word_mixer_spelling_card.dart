import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/daily_challenges/word_mixer/domain/models/word_mixer_puzzle.dart';

/// Unique token representing a letter tile in the Word Mixer game.
class _LetterTile {
  final int id;
  final String char;

  const _LetterTile({required this.id, required this.char});
}

/// Dedicated, bespoke interactive spelling assembly card for Word Mixer.
///
/// Features:
/// 1. Answer Construction Rack: Interactive slots showing placed letters.
/// 2. Tap-to-remove: Tapping any placed letter returns it to the bank.
/// 3. Tactile Letter Bank: Scrambled pool of letters with shuffle and clear actions.
/// 4. Submit-Only Flow: "CHECK ANSWER" button only (no skip button or loopholes).
/// 5. Non-Punitive Learning: Wrong attempts shake gently with haptic feedback,
///    never terminating the game with a Game Over dialog.
class WordMixerSpellingCard extends StatefulWidget {
  final WordMixerPuzzle puzzle;
  final Color primaryColor;
  final VoidCallback onSuccess;
  final SoundService soundService;
  final HapticService hapticService;

  const WordMixerSpellingCard({
    super.key,
    required this.puzzle,
    required this.primaryColor,
    required this.onSuccess,
    required this.soundService,
    required this.hapticService,
  });

  @override
  State<WordMixerSpellingCard> createState() => _WordMixerSpellingCardState();
}

class _WordMixerSpellingCardState extends State<WordMixerSpellingCard>
    with SingleTickerProviderStateMixin {
  late List<_LetterTile> _allTiles;
  late List<_LetterTile> _bankTiles;
  final List<_LetterTile> _placedTiles = [];

  bool _isSuccess = false;
  bool _isWrong = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initTiles();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant WordMixerSpellingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.puzzle.id != widget.puzzle.id ||
        oldWidget.puzzle.word != widget.puzzle.word) {
      _initTiles();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _initTiles() {
    final rawWord = widget.puzzle.word.toUpperCase();
    _allTiles = List.generate(
      rawWord.length,
      (i) => _LetterTile(id: i, char: rawWord[i]),
    );

    // Deterministically scramble letters so it never matches the target word initially
    final rand = Random(widget.puzzle.id);
    _bankTiles = List.from(_allTiles)..shuffle(rand);

    // If inadvertently shuffled into the solved word, swap first two distinct chars
    if (_bankTiles.map((t) => t.char).join() == rawWord && _bankTiles.length > 1) {
      for (int i = 0; i < _bankTiles.length - 1; i++) {
        if (_bankTiles[i].char != _bankTiles[i + 1].char) {
          final temp = _bankTiles[i];
          _bankTiles[i] = _bankTiles[i + 1];
          _bankTiles[i + 1] = temp;
          break;
        }
      }
    }

    _placedTiles.clear();
    _isSuccess = false;
    _isWrong = false;
  }

  void _onTapBankTile(_LetterTile tile) {
    if (_isSuccess) return;
    widget.hapticService.selection();

    setState(() {
      _isWrong = false;
      _bankTiles.remove(tile);
      _placedTiles.add(tile);
    });
  }

  void _onTapPlacedTile(int index) {
    if (_isSuccess) return;
    widget.hapticService.selection();

    setState(() {
      _isWrong = false;
      final removed = _placedTiles.removeAt(index);
      _bankTiles.add(removed);
    });
  }

  void _onClearAll() {
    if (_placedTiles.isEmpty || _isSuccess) return;
    widget.hapticService.light();

    setState(() {
      _isWrong = false;
      _bankTiles.addAll(_placedTiles);
      _placedTiles.clear();
    });
  }

  void _onShuffleBank() {
    if (_bankTiles.length <= 1 || _isSuccess) return;
    widget.hapticService.light();

    setState(() {
      _bankTiles.shuffle();
    });
  }

  void _onSubmit() {
    if (_isSuccess) return;
    if (_placedTiles.length < widget.puzzle.letterCount) return;

    final assembled = _placedTiles.map((t) => t.char).join();

    if (assembled == widget.puzzle.word.toUpperCase()) {
      setState(() {
        _isSuccess = true;
        _isWrong = false;
      });
      widget.hapticService.success();
      widget.soundService.playCorrect();
      widget.onSuccess();
    } else {
      widget.hapticService.error();
      widget.soundService.playWrong();

      setState(() {
        _isWrong = true;
      });

      _shakeController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _isWrong = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalLetters = widget.puzzle.letterCount;
    final isComplete = _placedTiles.length == totalLetters;

    final cardBgGradient = LinearGradient(
      colors: isDark
          ? [
              const Color(0xFF1E1035).withValues(alpha: 0.8),
              const Color(0xFF0F172A).withValues(alpha: 0.9),
            ]
          : [
              Colors.white,
              const Color(0xFFFAF5FF),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: cardBgGradient,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: _isSuccess
              ? AppColors.emerald500
              : (_isWrong
                  ? AppColors.red500.withValues(alpha: 0.8)
                  : widget.primaryColor.withValues(alpha: isDark ? 0.35 : 0.22)),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: _isSuccess
                ? AppColors.emerald500.withValues(alpha: 0.2)
                : widget.primaryColor.withValues(alpha: isDark ? 0.15 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Header with Title & Action Controls ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('home.spell_it', fallback: 'SPELL IT!'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${_placedTiles.length}/$totalLetters letters placed',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Toolbar: Shuffle + Clear
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Shuffle Remaining Button
                  Semantics(
                    button: true,
                    label: 'Shuffle bank letters',
                    child: ScaleButton(
                      onTap: _onShuffleBank,
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: widget.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.shuffle_rounded,
                          size: 18.r,
                          color: widget.primaryColor,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 8.w),

                  // Clear All Button
                  Semantics(
                    button: true,
                    label: 'Clear all placed letters',
                    child: ScaleButton(
                      onTap: _onClearAll,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 7.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 15.r,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              context.tr('common.clear', fallback: 'Clear'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 18.h),

          // ── 2. Answer Construction Rack (Slots) ───────────────────────────
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              final offset = sin(_shakeAnimation.value * pi * 4) * 8;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: _isSuccess
                      ? AppColors.emerald500
                      : (_isWrong
                          ? AppColors.red500.withValues(alpha: 0.8)
                          : widget.primaryColor.withValues(alpha: 0.2)),
                  width: 1.5.w,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalLetters, (index) {
                    final hasTile = index < _placedTiles.length;
                    final tile = hasTile ? _placedTiles[index] : null;

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: hasTile
                          ? ScaleButton(
                              onTap: () => _onTapPlacedTile(index),
                              child: Container(
                                width: 42.r,
                                height: 48.r,
                                decoration: BoxDecoration(
                                  gradient: _isSuccess
                                      ? const LinearGradient(
                                          colors: [
                                            AppColors.emerald500,
                                            AppColors.emerald600,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : LinearGradient(
                                          colors: isDark
                                              ? [
                                                  widget.primaryColor.withValues(alpha: 0.45),
                                                  widget.primaryColor.withValues(alpha: 0.25),
                                                ]
                                              : [
                                                  widget.primaryColor.withValues(alpha: 0.15),
                                                  widget.primaryColor.withValues(alpha: 0.08),
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: _isSuccess
                                        ? AppColors.emerald500
                                        : (_isWrong
                                            ? AppColors.red500
                                            : widget.primaryColor.withValues(alpha: 0.4)),
                                    width: 1.5.w,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.05,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    tile!.char,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w700,
                                      color: _isSuccess
                                          ? Colors.white
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: 42.r,
                              height: 48.r,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : Colors.black.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.black.withValues(alpha: 0.12),
                                  width: 1.2.w,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 8.r,
                                  height: 2.h,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white30 : Colors.black26,
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                              ),
                            ),
                    );
                  }),
                ),
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // ── 3. Letter Bank ────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: widget.primaryColor.withValues(alpha: 0.12),
                width: 1.w,
              ),
            ),
            child: _bankTiles.isEmpty
                ? SizedBox(
                    height: 48.r,
                    child: Center(
                      child: Text(
                        context.tr(
                          'home.all_letters_used',
                          fallback: 'All letters placed. Tap any letter above to remove it.',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ),
                  )
                : Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: _bankTiles.map((tile) {
                      return ScaleButton(
                        onTap: () => _onTapBankTile(tile),
                        child: Container(
                          width: 44.r,
                          height: 48.r,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2E1A47)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: widget.primaryColor.withValues(alpha: 0.35),
                              width: 1.2.w,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.primaryColor.withValues(
                                  alpha: isDark ? 0.25 : 0.08,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              tile.char,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: widget.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),

          SizedBox(height: 22.h),

          // ── 4. Submit-Only Button (No Skip Allowed) ─────────────────────────
          ScaleButton(
            onTap: isComplete ? _onSubmit : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 15.h),
              decoration: BoxDecoration(
                gradient: isComplete
                    ? LinearGradient(
                        colors: [
                          widget.primaryColor,
                          widget.primaryColor.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isComplete
                    ? null
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: isComplete
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSuccess ? Icons.check_circle_rounded : Icons.check_rounded,
                        color: isComplete
                            ? Colors.white
                            : (isDark ? Colors.white30 : Colors.black26),
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _isSuccess
                            ? context.tr('common.correct', fallback: 'SOLVED!')
                            : context.tr('common.check_answer', fallback: 'CHECK ANSWER'),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: isComplete
                              ? Colors.white
                              : (isDark ? Colors.white30 : Colors.black26),
                          letterSpacing: 0.8,
                        ),
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

