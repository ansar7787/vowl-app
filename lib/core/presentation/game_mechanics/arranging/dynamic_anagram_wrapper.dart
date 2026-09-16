import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/game_skip_bypass_button.dart';

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
  final int maxAttempts;

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
    this.maxAttempts = 3,
  });

  @override
  State<DynamicAnagramWrapper> createState() => _DynamicAnagramWrapperState();
}

class _DynamicAnagramWrapperState extends State<DynamicAnagramWrapper> {
  late ValueNotifier<List<_Tile>> _availableTiles;
  late ValueNotifier<List<_Tile?>> _placedTiles;
  final ValueNotifier<bool> _hasError = ValueNotifier(false);
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);
  final ValueNotifier<int> _attempts = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void dispose() {
    _availableTiles.dispose();
    _placedTiles.dispose();
    _hasError.dispose();
    _isSubmitting.dispose();
    _attempts.dispose();
    super.dispose();
  }

  void _initGame() {
    String text = widget.expectedText.toUpperCase().trim();
    List<_Tile?> initPlaced = List.filled(text.length, null);
    List<_Tile> initAvailable = [];

    for (int i = 0; i < text.length; i++) {
      if (text[i] == ' ') {
        initPlaced[i] = _Tile(id: -1, letter: ' ');
      } else {
        initAvailable.add(_Tile(id: i, letter: text[i]));
      }
    }
    initAvailable.shuffle();
    _availableTiles = ValueNotifier(initAvailable);
    _placedTiles = ValueNotifier(initPlaced);
  }

  void _onAvailableTileTapped(_Tile tile) {
    if (_isSubmitting.value) return;
    if (!_availableTiles.value.contains(tile)) return; // Anti-double-tap guard
    if (_hasError.value) _hasError.value = false;
    HapticFeedback.lightImpact();

    final currentPlaced = List<_Tile?>.from(_placedTiles.value);
    int emptyIndex = currentPlaced.indexWhere((t) => t == null);
    if (emptyIndex != -1) {
      currentPlaced[emptyIndex] = tile;
      _placedTiles.value = currentPlaced;

      final currentAvail = List<_Tile>.from(_availableTiles.value);
      currentAvail.remove(tile);
      _availableTiles.value = currentAvail;

      if (!currentPlaced.contains(null)) {
        _onSubmit();
      }
    }
  }

  void _onPlacedTileTapped(int index) {
    if (_isSubmitting.value) return;
    if (_hasError.value) _hasError.value = false;

    final currentPlaced = List<_Tile?>.from(_placedTiles.value);
    _Tile? tile = currentPlaced[index];
    if (tile != null && tile.id != -1) {
      HapticFeedback.lightImpact();
      currentPlaced[index] = null;
      _placedTiles.value = currentPlaced;

      final currentAvail = List<_Tile>.from(_availableTiles.value);
      currentAvail.add(tile);
      _availableTiles.value = currentAvail;
    }
  }

  void _onTileDropped(int index, _Tile tile) {
    if (_isSubmitting.value) return;
    _hasError.value = false;

    final currentPlaced = List<_Tile?>.from(_placedTiles.value);
    final currentAvail = List<_Tile>.from(_availableTiles.value);

    // Is the dropped tile already in the placed list?
    final oldIndex = currentPlaced.indexOf(tile);

    if (oldIndex != -1) {
      // Dragged from another placed slot. Swap them.
      // But only if the existing tile is movable (not pre-filled)
      final existingAtNew = currentPlaced[index];
      if (existingAtNew != null && existingAtNew.id == -1) {
        return; // Can't swap with pre-filled
      }

      currentPlaced[index] = tile;
      currentPlaced[oldIndex] = existingAtNew;
    } else {
      // Dragged from available bank
      final existingAtNew = currentPlaced[index];
      if (existingAtNew != null && existingAtNew.id == -1) {
        return; // Can't replace pre-filled
      }

      currentPlaced[index] = tile;
      currentAvail.remove(tile);
      if (existingAtNew != null) {
        currentAvail.add(existingAtNew);
      }
    }

    _placedTiles.value = currentPlaced;
    _availableTiles.value = currentAvail;
    HapticFeedback.lightImpact();

    if (!currentPlaced.contains(null)) {
      _onSubmit();
    }
  }

  void _clearAll() {
    if (_isSubmitting.value) return;
    _hasError.value = false;

    final currentPlaced = List<_Tile?>.from(_placedTiles.value);
    final currentAvail = List<_Tile>.from(_availableTiles.value);

    for (int i = 0; i < currentPlaced.length; i++) {
      final tile = currentPlaced[i];
      if (tile != null && tile.id != -1) {
        currentAvail.add(tile);
        currentPlaced[i] = null;
      }
    }
    currentAvail.shuffle();

    _placedTiles.value = currentPlaced;
    _availableTiles.value = currentAvail;
  }

  void _onSubmit() {
    if (_isSubmitting.value) return;

    final currentPlaced = _placedTiles.value;
    if (currentPlaced.contains(null)) {
      HapticFeedback.heavyImpact();
      _hasError.value = true;
      return;
    }

    String currentWord = currentPlaced.map((t) => t!.letter).join('');
    if (currentWord == widget.expectedText.toUpperCase().trim()) {
      HapticFeedback.mediumImpact();
      _isSubmitting.value = true;
      if (widget.bonusCoins != null &&
          widget.bonusCoins! > 0 &&
          _attempts.value < widget.maxAttempts) {
        context.read<EconomyBloc>().add(
          EconomyAddCoinsRequested(widget.bonusCoins!),
        );
      }
      widget.onConfirmed();
    } else {
      HapticFeedback.heavyImpact();
      _hasError.value = true;
      _attempts.value++;

      if (_attempts.value >= widget.maxAttempts) {
        _isSubmitting.value = true;
        Future.delayed(400.ms, () {
          if (!mounted) return;
          if (widget.onFailedWithSpelling != null) {
            widget.onFailedWithSpelling!(currentWord);
          } else {
            widget.onFailed();
          }
        });
      } else {
        // They have more attempts, clear the board automatically after a short delay
        _isSubmitting.value = true;
        Future.delayed(600.ms, () {
          if (!mounted) return;
          _isSubmitting.value = false;
          _clearAll();
        });
      }
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
          final availableWidth = constraints.maxWidth > 0
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;

          final int maxCharsPerLine = math.max(
            1,
            math.min(_placedTiles.value.length, 9),
          );
          final double horizontalPadding = 48.w;
          final double tileSpacing = 6.w;

          double calcWidth =
              (availableWidth -
                  horizontalPadding -
                  (maxCharsPerLine * tileSpacing)) /
              maxCharsPerLine;
          final double tileW = calcWidth.clamp(28.w, 44.w);
          final double tileH = tileW * 1.25;

          return ValueListenableBuilder<bool>(
            valueListenable: _hasError,
            builder: (context, hasError, child) {
              return Container(
                padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: widget.isPositioned
                      ? BorderRadius.vertical(top: Radius.circular(32.r))
                      : BorderRadius.circular(32.r),
                  border: Border.all(
                    color: hasError
                        ? errorColor.withValues(alpha: 0.5)
                        : widget.primaryColor.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: hasError
                          ? errorColor.withValues(alpha: 0.15)
                          : widget.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: child,
              );
            },
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
                            color: widget.primaryColor.withValues(alpha: 0.12),
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
                                  widget.primaryColor.withValues(alpha: 0.7),
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

                    // Clear All button
                    ValueListenableBuilder<bool>(
                      valueListenable: _isSubmitting,
                      builder: (context, isSubmitting, _) {
                        return ValueListenableBuilder<List<_Tile?>>(
                          valueListenable: _placedTiles,
                          builder: (context, placedTiles, _) {
                            if (placedTiles.any(
                                  (t) => t != null && t.id != -1,
                                ) &&
                                !isSubmitting) {
                              return Padding(
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
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        );
                      },
                    ),
                    SizedBox(height: 24.h),

                    // Placed Tiles (Slots)
                    ValueListenableBuilder<bool>(
                      valueListenable: _hasError,
                      builder: (context, hasError, _) {
                        return ValueListenableBuilder<List<_Tile?>>(
                          valueListenable: _placedTiles,
                          builder: (context, placedTiles, _) {
                            return Wrap(
                                  spacing: tileSpacing,
                                  runSpacing: tileSpacing,
                                  alignment: WrapAlignment.center,
                                  children: List.generate(placedTiles.length, (
                                    index,
                                  ) {
                                    final tile = placedTiles[index];
                                    if (tile != null && tile.id == -1) {
                                      return SizedBox(
                                        key: ValueKey('space_$index'),
                                        width: tileW * 0.4,
                                        height: tileH,
                                      );
                                    }
                                    return DragTarget<_Tile>(
                                      onAcceptWithDetails: (details) =>
                                          _onTileDropped(index, details.data),
                                      builder:
                                          (
                                            context,
                                            candidateData,
                                            rejectedData,
                                          ) {
                                            final isHovering =
                                                candidateData.isNotEmpty;

                                            if (tile == null) {
                                              return Container(
                                                key: ValueKey('empty_$index'),
                                                width: tileW,
                                                height: tileH,
                                                decoration: BoxDecoration(
                                                  color:
                                                      (isDark
                                                              ? Colors.white10
                                                              : Colors.black
                                                                    .withValues(
                                                                      alpha:
                                                                          0.05,
                                                                    ))
                                                          .withValues(
                                                            alpha: isHovering
                                                                ? 0.2
                                                                : 0.05,
                                                          ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.r,
                                                      ),
                                                  border: isHovering
                                                      ? Border.all(
                                                          color: widget
                                                              .primaryColor
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                        )
                                                      : null,
                                                ),
                                              );
                                            }

                                            return Draggable<_Tile>(
                                              data: tile,
                                              childWhenDragging: Opacity(
                                                opacity: 0.3,
                                                child: _buildTileWidget(
                                                  tile,
                                                  tileW,
                                                  tileH,
                                                  isDark,
                                                  subtitleColor,
                                                  textColor,
                                                  isPlaced: true,
                                                ),
                                              ),
                                              feedback: Material(
                                                color: Colors.transparent,
                                                child: Transform.scale(
                                                  scale: 1.1,
                                                  child: _buildTileWidget(
                                                    tile,
                                                    tileW,
                                                    tileH,
                                                    isDark,
                                                    subtitleColor,
                                                    textColor,
                                                    isPlaced: true,
                                                  ),
                                                ),
                                              ),
                                              child: GestureDetector(
                                                key: ValueKey(
                                                  'placed_${tile.id}',
                                                ),
                                                onTap: () =>
                                                    _onPlacedTileTapped(index),
                                                child:
                                                    _buildTileWidget(
                                                          tile,
                                                          tileW,
                                                          tileH,
                                                          isDark,
                                                          subtitleColor,
                                                          textColor,
                                                          isPlaced: true,
                                                          isHovering:
                                                              isHovering,
                                                        )
                                                        .animate(
                                                          key: ValueKey(
                                                            'anim_placed_${tile.id}',
                                                          ),
                                                        )
                                                        .scaleXY(
                                                          begin: 0.7,
                                                          end: 1.0,
                                                          curve: Curves
                                                              .easeOutBack,
                                                          duration: 250.ms,
                                                        ),
                                              ),
                                            );
                                          },
                                    );
                                  }),
                                )
                                .animate(target: hasError ? 1 : 0)
                                .shakeX(amount: 5, duration: 400.ms);
                          },
                        );
                      },
                    ),

                    SizedBox(height: 24.h),

                    // Available Tiles
                    ValueListenableBuilder<List<_Tile>>(
                      valueListenable: _availableTiles,
                      builder: (context, availableTiles, _) {
                        return DragTarget<_Tile>(
                          onAcceptWithDetails: (details) {
                            final tile = details.data;
                            final currentPlaced = List<_Tile?>.from(
                              _placedTiles.value,
                            );
                            final index = currentPlaced.indexOf(tile);
                            if (index != -1) {
                              _onPlacedTileTapped(index);
                            }
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              constraints: BoxConstraints(minHeight: tileH),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: candidateData.isNotEmpty
                                    ? widget.primaryColor.withValues(
                                        alpha: 0.05,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Wrap(
                                spacing: tileSpacing,
                                runSpacing: tileSpacing,
                                alignment: WrapAlignment.center,
                                children: availableTiles.map((tile) {
                                  return Draggable<_Tile>(
                                    data: tile,
                                    feedback: Material(
                                      color: Colors.transparent,
                                      child: Transform.scale(
                                        scale: 1.1,
                                        child: _buildTileWidget(
                                          tile,
                                          tileW,
                                          tileH,
                                          isDark,
                                          subtitleColor,
                                          textColor,
                                        ),
                                      ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.3,
                                      child: _buildTileWidget(
                                        tile,
                                        tileW,
                                        tileH,
                                        isDark,
                                        subtitleColor,
                                        textColor,
                                      ),
                                    ),
                                    child: GestureDetector(
                                      key: ValueKey('avail_${tile.id}'),
                                      onTap: () => _onAvailableTileTapped(tile),
                                      child:
                                          _buildTileWidget(
                                                tile,
                                                tileW,
                                                tileH,
                                                isDark,
                                                subtitleColor,
                                                textColor,
                                              )
                                              .animate(
                                                key: ValueKey(
                                                  'anim_avail_${tile.id}',
                                                ),
                                              )
                                              .scaleXY(
                                                begin: 0.9,
                                                end: 1.0,
                                                curve: Curves.easeOutBack,
                                                duration: 200.ms,
                                              ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    SizedBox(height: 32.h),

                    // Controls
                    ValueListenableBuilder<bool>(
                      valueListenable: _hasError,
                      builder: (context, hasError, _) {
                        return ValueListenableBuilder<bool>(
                          valueListenable: _isSubmitting,
                          builder: (context, isSubmitting, _) {
                            return ValueListenableBuilder<List<_Tile?>>(
                              valueListenable: _placedTiles,
                              builder: (context, placedTiles, _) {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed:
                                            (placedTiles.contains(null) ||
                                                isSubmitting)
                                            ? null
                                            : _onSubmit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: hasError
                                              ? errorColor
                                              : widget.primaryColor,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 16.h,
                                          ),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                          ),
                                        ),
                                        child: AutoSizeText(
                                          context.tr(
                                            'game.submit_button',
                                            fallback: 'Submit',
                                          ),
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
                                );
                              },
                            );
                          },
                        );
                      },
                    ),

                    // Skip button
                    if (widget.allowSkip)
                      Padding(
                        padding: EdgeInsets.only(top: 16.h),
                        child: GameSkipBypassButton(
                          subtitleColor: subtitleColor,
                          isSubmitting: _isSubmitting,
                          attempts: _attempts,
                          maxAttempts: widget.maxAttempts,
                          onBypassed: widget.onBypassed,
                          onConfirmed: widget.onConfirmed,
                          onSkipped: widget.onFailed,
                          onSubmittingChanged: (v) => _isSubmitting.value = v,
                          skipLabel: context.tr(
                            'game.skip_button',
                            fallback: 'SKIP',
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
    ).animate().slideY(begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOut).fadeIn(duration: 300.ms);

    if (widget.isPositioned) {
      return Positioned(bottom: 0, left: 0, right: 0, child: content);
    }

    return content;
  }

  Widget _buildTileWidget(
    _Tile tile,
    double tileW,
    double tileH,
    bool isDark,
    Color subtitleColor,
    Color textColor, {
    bool isPlaced = false,
    bool isHovering = false,
  }) {
    return Container(
      width: tileW,
      height: tileH,
      decoration: BoxDecoration(
        color: isPlaced
            ? widget.primaryColor.withValues(alpha: isHovering ? 0.3 : 0.1)
            : (isDark ? const Color(0xFF1E1E2C) : Colors.white),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isPlaced
              ? widget.primaryColor.withValues(alpha: isHovering ? 0.8 : 0.5)
              : subtitleColor.withValues(alpha: 0.2),
        ),
        boxShadow: isPlaced
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
    );
  }
}

class _Tile {
  final int id;
  final String letter;
  _Tile({required this.id, required this.letter});
}
