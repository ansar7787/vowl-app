import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/ad_service.dart';

class DynamicAnagramWrapper extends StatefulWidget {
  final String expectedText;
  final Color primaryColor;
  final VoidCallback onConfirmed;
  final VoidCallback onFailed;
  final Function(String)? onFailedWithSpelling;
  final int? bonusCoins;
  final VoidCallback? onBypassed;
  final bool allowSkip;

  final String? title;
  final String? subtitle;
  final bool isPositioned;

  const DynamicAnagramWrapper({
    super.key,
    required this.expectedText,
    required this.primaryColor,
    required this.onConfirmed,
    required this.onFailed,
    this.onFailedWithSpelling,
    this.bonusCoins = 5,
    this.onBypassed,
    this.allowSkip = true,
    this.title,
    this.subtitle,
    this.isPositioned = true,
  });

  @override
  State<DynamicAnagramWrapper> createState() => _DynamicAnagramWrapperState();
}

class _DynamicAnagramWrapperState extends State<DynamicAnagramWrapper> {
  late List<_Tile> _availableTiles;
  late List<_Tile?> _placedTiles;
  bool _hasError = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    String text = widget.expectedText.toUpperCase().trim();
    _placedTiles = List.filled(text.length, null);
    _availableTiles = [];

    for (int i = 0; i < text.length; i++) {
      if (text[i] == ' ') {
        // Pre-fill spaces to handle the edge case automatically
        _placedTiles[i] = _Tile(id: -1, letter: ' ');
      } else {
        _availableTiles.add(_Tile(id: i, letter: text[i]));
      }
    }
    _availableTiles.shuffle();
  }

  void _onAvailableTileTapped(_Tile tile) {
    if (_isSubmitting) return;
    if (_hasError) setState(() => _hasError = false);
    HapticFeedback.lightImpact();

    int emptyIndex = _placedTiles.indexWhere((t) => t == null);
    if (emptyIndex != -1) {
      setState(() {
        _placedTiles[emptyIndex] = tile;
        _availableTiles.remove(tile);
      });

      // Auto-submit if the word is fully placed and correct
      if (!_placedTiles.contains(null)) {
        String currentWord = _placedTiles.map((t) => t!.letter).join('');
        if (currentWord == widget.expectedText.toUpperCase().trim()) {
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

    _Tile? tile = _placedTiles[index];
    if (tile != null && tile.id != -1) {
      HapticFeedback.lightImpact();
      // -1 is a fixed space character
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
        if (tile != null && tile.id != -1) {
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

    String currentWord = _placedTiles.map((t) => t!.letter).join('');
    if (currentWord == widget.expectedText.toUpperCase().trim()) {
      HapticFeedback.mediumImpact();
      setState(() => _isSubmitting = true);
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
        _isSubmitting = true;
      });
      Future.delayed(400.ms, () {
        if (!mounted) return;
        if (widget.onFailedWithSpelling != null) {
          widget.onFailedWithSpelling!(currentWord);
        } else {
          widget.onFailed();
        }
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Dynamic constraint calculation to prevent Overflow on tiny screens
          final availableWidth = constraints.maxWidth > 0 
              ? constraints.maxWidth 
              : MediaQuery.of(context).size.width;
              
          final int maxCharsPerLine = math.max(1, math.min(_placedTiles.length, 9));
          final double horizontalPadding = 48.w; // 24.w on each side
          final double tileSpacing = 6.w;
          
          double calcWidth = (availableWidth - horizontalPadding - (maxCharsPerLine * tileSpacing)) / maxCharsPerLine;
          // Clamp tile sizes so they never look absurdly small or large
          final double tileW = calcWidth.clamp(28.w, 44.w);
          final double tileH = tileW * 1.25;

          return Container(
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
                            Icons.spellcheck_rounded,
                            color: widget.primaryColor,
                            size: 22.r,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                widget.title ?? 'NOW SPELL IT!',
                                maxLines: 1,
                                minFontSize: 4,
                                stepGranularity: 0.5,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: widget.primaryColor,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              AutoSizeText(
                                widget.subtitle ??
                                    'Tap the letters in the correct order',
                                maxLines: 2,
                                minFontSize: 4,
                                stepGranularity: 0.5,
                                overflow: TextOverflow.visible,
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
                        if (widget.bonusCoins != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.primaryColor,
                                  widget.primaryColor.withValues(
                                    alpha: 0.7,
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: AutoSizeText(
                              '+${widget.bonusCoins} Coins',
                              maxLines: 1,
                              minFontSize: 4,
                              stepGranularity: 0.5,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Clear All button (only show when tiles are placed)
                    if (_placedTiles.any((t) => t != null && t.id != -1) && !_isSubmitting)
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

                    // Placed Tiles (Slots)
                    Wrap(
                          spacing: tileSpacing,
                          runSpacing: tileSpacing,
                          alignment: WrapAlignment.center,
                          children: List.generate(_placedTiles.length, (
                            index,
                          ) {
                            final tile = _placedTiles[index];
                            if (tile != null && tile.id == -1) {
                              // Render empty space for multi-word answers
                              return SizedBox(key: ValueKey('space_$index'), width: tileW * 0.4, height: tileH);
                            }
                            return GestureDetector(
                              key: tile != null ? ValueKey('placed_${tile.id}') : ValueKey('empty_$index'),
                              onTap: () => _onPlacedTileTapped(index),
                              child: Container(
                                width: tileW,
                                height: tileH,
                                decoration: BoxDecoration(
                                  color: tile != null
                                      ? widget.primaryColor.withValues(
                                          alpha: 0.1,
                                        )
                                      : (isDark
                                            ? Colors.white10
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              )),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: tile != null
                                        ? widget.primaryColor.withValues(
                                            alpha: 0.5,
                                          )
                                        : Colors.transparent,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: tile != null
                                    ? AutoSizeText(
                                        tile.letter,
                                        maxLines: 1,
                                        minFontSize: 4,
                                        stepGranularity: 0.5,
                                        overflow: TextOverflow.visible,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ).animate(key: ValueKey('anim_placed_${tile.id}')).scaleXY(begin: 0.7, end: 1.0, curve: Curves.easeOutBack, duration: 250.ms)
                                    : null,
                              ),
                            );
                          }),
                        )
                        .animate(target: _hasError ? 1 : 0)
                        .shakeX(amount: 5, duration: 400.ms),

                    SizedBox(height: 24.h),

                    // Available Tiles
                    Wrap(
                      spacing: tileSpacing,
                      runSpacing: tileSpacing,
                      alignment: WrapAlignment.center,
                      children: _availableTiles.map((tile) {
                        return GestureDetector(
                          key: ValueKey('avail_${tile.id}'),
                          onTap: () => _onAvailableTileTapped(tile),
                          child: Container(
                            width: tileW,
                            height: tileH,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E1E2C)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
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
                            alignment: Alignment.center,
                            child: AutoSizeText(
                              tile.letter,
                              maxLines: 1,
                              minFontSize: 4,
                              stepGranularity: 0.5,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ).animate(key: ValueKey('anim_avail_${tile.id}')).scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack, duration: 200.ms);
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
                            child: AutoSizeText(
                              'Submit',
                              maxLines: 1,
                              minFontSize: 4,
                              stepGranularity: 0.5,
                              overflow: TextOverflow.visible,
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
                                widget.onConfirmed();
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
                                      widget.onConfirmed();
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
          );
        },
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

class _Tile {
  final int id;
  final String letter;
  _Tile({required this.id, required this.letter});
}
