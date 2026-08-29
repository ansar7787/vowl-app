import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/ad_service.dart';

class DynamicJigsawWrapper extends StatefulWidget {
  final String expectedText;
  final Color primaryColor;
  final VoidCallback onConfirmed;
  final VoidCallback onSkipped;
  final VoidCallback? onBypassed;
  final int? bonusCoins;
  final bool allowSkip;
  final bool isPositioned;

  const DynamicJigsawWrapper({
    super.key,
    required this.expectedText,
    required this.primaryColor,
    required this.onConfirmed,
    required this.onSkipped,
    this.onBypassed,
    this.bonusCoins = 5,
    this.allowSkip = true,
    this.isPositioned = true,
  });

  @override
  State<DynamicJigsawWrapper> createState() => _DynamicJigsawWrapperState();
}

class _DynamicJigsawWrapperState extends State<DynamicJigsawWrapper> {
  late List<_WordTile> _availableTiles;
  late List<_WordTile?> _placedTiles;
  late String _targetSentence;
  bool _hasError = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    // Split sentence by spaces
    List<String> rawWords = widget.expectedText.trim().split(RegExp(r'\s+'));

    _placedTiles = List.filled(rawWords.length, null);
    _availableTiles = [];

    List<String> cleanedWords = [];
    for (int i = 0; i < rawWords.length; i++) {
      // Loophole Fixes:
      // 1. Lowercase to prevent capital-letter exploits.
      // 2. Strip trailing punctuation so it doesn't give away the last word.
      String cleanedWord = rawWords[i].toLowerCase().replaceAll(
        RegExp(r'[.,!?]$'),
        '',
      );

      cleanedWords.add(cleanedWord);
      _availableTiles.add(_WordTile(id: i, word: cleanedWord));
    }

    _targetSentence = cleanedWords.join(' ');

    _availableTiles.shuffle();
  }

  void _onAvailableTileTapped(_WordTile tile) {
    if (_isSubmitting) return;
    if (_hasError) setState(() => _hasError = false);
    HapticFeedback.lightImpact();

    int emptyIndex = _placedTiles.indexWhere((t) => t == null);
    if (emptyIndex != -1) {
      setState(() {
        _placedTiles[emptyIndex] = tile;
        _availableTiles.remove(tile);
      });

      // Auto-submit if all tiles are placed and correct
      if (!_placedTiles.contains(null)) {
        String currentSentence = _placedTiles.map((t) => t!.word).join(' ');
        if (currentSentence == _targetSentence) {
          _onSubmit();
        } else {
          HapticFeedback.heavyImpact();
          setState(() => _hasError = true);
        }
      }
    }
  }

  void _onPlacedTileTapped(int index) {
    if (_isSubmitting) return;
    if (_hasError) setState(() => _hasError = false);

    _WordTile? tile = _placedTiles[index];
    if (tile != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _placedTiles[index] = null;
        _availableTiles.add(tile);
      });
    }
  }

  void _clearAll() {
    if (_isSubmitting) return;
    setState(() {
      _hasError = false;
      for (int i = 0; i < _placedTiles.length; i++) {
        final tile = _placedTiles[i];
        if (tile != null) {
          _availableTiles.add(tile);
          _placedTiles[i] = null;
        }
      }
      _availableTiles.shuffle();
    });
  }

  void _onSubmit() {
    if (_isSubmitting) return;
    if (_placedTiles.contains(null)) {
      HapticFeedback.heavyImpact();
      setState(() => _hasError = true);
      return;
    }

    String currentSentence = _placedTiles.map((t) => t!.word).join(' ');

    if (currentSentence == _targetSentence) {
      HapticFeedback.mediumImpact();
      setState(() => _isSubmitting = true);
      // Award bonus coins
      if (widget.bonusCoins != null && widget.bonusCoins! > 0) {
        context.read<EconomyBloc>().add(
          EconomyAddCoinsRequested(widget.bonusCoins!),
        );
      }
      widget.onConfirmed();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0C0C1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final errorColor = Colors.redAccent;

    final content = Material(
      type: MaterialType.transparency,
      child: Container(
                  padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32.r),
                    ),
                    border: Border.all(
                      color: _hasError
                          ? errorColor.withValues(alpha: 0.5)
                          : widget.primaryColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _hasError
                            ? errorColor.withValues(alpha: 0.15)
                            : widget.primaryColor.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle bar
                          Container(
                            width: 48.w,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: subtitleColor.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // Header
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.r),
                                decoration: BoxDecoration(
                                  color: widget.primaryColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: Icon(
                                  Icons.extension_rounded,
                                  color: widget.primaryColor,
                                  size: 22.r,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'BUILD THE SENTENCE!',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w900,
                                        color: widget.primaryColor,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Tap the words in the correct grammatical order',
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w500,
                                        color: subtitleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Word count badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  '${_placedTiles.length} words',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: widget.primaryColor,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Clear All button (only show when tiles are placed)
                          if (_placedTiles.any((t) => t != null) && !_isSubmitting)
                            Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: GestureDetector(
                                onTap: _clearAll,
                                child: Text(
                                  'CLEAR ALL',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    color: subtitleColor,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(height: 24.h),

                          // Placed Tiles (Sentence Builder Area)
                          Container(
                                width: double.infinity,
                                constraints: BoxConstraints(minHeight: 60.h),
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.02),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: _hasError
                                        ? errorColor.withValues(alpha: 0.5)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: List.generate(_placedTiles.length, (
                                    index,
                                  ) {
                                    final tile = _placedTiles[index];
                                    if (tile == null) {
                                      // Empty slot indicator
                                      return Container(
                                        key: ValueKey('empty_$index'),
                                        height: 36.h,
                                        width: 50.w,
                                        decoration: BoxDecoration(
                                          color: widget.primaryColor.withValues(
                                            alpha: 0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            18.r,
                                          ),
                                          border: Border.all(
                                            color: widget.primaryColor.withValues(
                                              alpha: 0.2,
                                            ),
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                      );
                                    }

                                    return GestureDetector(
                                      key: ValueKey('placed_${tile.id}'),
                                      onTap: () => _onPlacedTileTapped(index),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 8.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: widget.primaryColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            18.r,
                                          ),
                                          border: Border.all(
                                            color: widget.primaryColor.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          tile.word,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      ).animate(key: ValueKey('anim_placed_${tile.id}')).scaleXY(begin: 0.8, end: 1.0, curve: Curves.easeOutBack, duration: 250.ms),
                                    );
                                  }),
                                ),
                              )
                              .animate(target: _hasError ? 1 : 0)
                              .shakeX(amount: 5, duration: 400.ms),

                          SizedBox(height: 24.h),

                          // Available Tiles (Word Bank)
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 12.h,
                            alignment: WrapAlignment.center,
                            children: _availableTiles.map((tile) {
                              return GestureDetector(
                                key: ValueKey('avail_${tile.id}'),
                                onTap: () => _onAvailableTileTapped(tile),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E1E2C)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18.r),
                                    border: Border.all(
                                      color: subtitleColor.withValues(alpha: 0.2),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    tile.word,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ).animate(key: ValueKey('anim_avail_${tile.id}')).scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack, duration: 200.ms),
                              );
                            }).toList(),
                          ),

                          SizedBox(height: 32.h),

                        // Controls
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    (_placedTiles.contains(null) ||
                                        _isSubmitting)
                                    ? null
                                    : _onSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _hasError
                                      ? errorColor
                                      : widget.primaryColor,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                ),
                                child: Text(
                                  'Submit',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Skip button
                        if (widget.allowSkip && !_isSubmitting)
                          Padding(
                            padding: EdgeInsets.only(top: 16.h),
                            child: ScaleButton(
                              onTap: () {
                                if (_isSubmitting) return;
                                final user = context.read<AuthBloc>().state.user;
                                final isPremium = user?.isPremium ?? false;
                                if (isPremium) {
                                  if (widget.onBypassed != null) {
                                    widget.onBypassed!();
                                  } else {
                                    widget.onSkipped();
                                  }
                                } else {
                                  di.sl<AdService>().showRewardedAd(
                                    context: context,
                                    isPremium: false,
                                    onUserEarnedReward: (_) {
                                      if (mounted) {
                                        if (widget.onBypassed != null) {
                                          widget.onBypassed!();
                                        } else {
                                          widget.onSkipped();
                                        }
                                      }
                                    },
                                    onDismissed: () {},
                                  );
                                }
                              },
                              child: Builder(
                                builder: (context) {
                                  final isPremium =
                                      context.watch<AuthBloc>().state.user?.isPremium ??
                                      false;
                                  return Text(
                                    isPremium ? 'SKIP' : 'WATCH AD TO BYPASS',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: subtitleColor,
                                      letterSpacing: 1.5,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .animate()
              .slideY(
                begin: 1.0,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 300.ms);

    if (widget.isPositioned) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: content,
      );
    }

    return content;
  }
}

class _WordTile {
  final int id;
  final String word;
  _WordTile({required this.id, required this.word});
}
