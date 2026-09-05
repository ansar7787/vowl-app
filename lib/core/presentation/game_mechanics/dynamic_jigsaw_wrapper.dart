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
  late ValueNotifier<List<_WordTile>> _availableTiles;
  late ValueNotifier<List<_WordTile?>> _placedTiles;
  late String _targetSentence;
  final ValueNotifier<bool> _hasError = ValueNotifier(false);
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);

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
    super.dispose();
  }

  void _initGame() {
    List<String> rawWords = widget.expectedText.trim().split(RegExp(r'\s+'));
    List<_WordTile?> initPlaced = List.filled(rawWords.length, null);
    List<_WordTile> initAvailable = [];

    List<String> cleanedWords = [];
    for (int i = 0; i < rawWords.length; i++) {
      String cleanedWord = rawWords[i].toLowerCase().replaceAll(
        RegExp(r'[.,!?]+$'),
        '',
      );

      cleanedWords.add(cleanedWord);
      initAvailable.add(_WordTile(id: i, word: cleanedWord));
    }

    _targetSentence = cleanedWords.join(' ');
    initAvailable.shuffle();

    _availableTiles = ValueNotifier(initAvailable);
    _placedTiles = ValueNotifier(initPlaced);
  }

  void _onAvailableTileTapped(_WordTile tile) {
    if (_isSubmitting.value) return;
    if (!_availableTiles.value.contains(tile)) return; // Anti-double-tap guard
    if (_hasError.value) _hasError.value = false;
    HapticFeedback.lightImpact();

    final currentPlaced = List<_WordTile?>.from(_placedTiles.value);
    int emptyIndex = currentPlaced.indexWhere((t) => t == null);
    if (emptyIndex != -1) {
      currentPlaced[emptyIndex] = tile;
      _placedTiles.value = currentPlaced;

      final currentAvail = List<_WordTile>.from(_availableTiles.value);
      currentAvail.remove(tile);
      _availableTiles.value = currentAvail;

      if (!currentPlaced.contains(null)) {
        String currentSentence = currentPlaced.map((t) => t!.word).join(' ');
        if (currentSentence == _targetSentence) {
          _onSubmit();
        } else {
          HapticFeedback.heavyImpact();
          _hasError.value = true;
        }
      }
    }
  }

  void _onPlacedTileTapped(int index) {
    if (_isSubmitting.value) return;
    if (_hasError.value) _hasError.value = false;

    final currentPlaced = List<_WordTile?>.from(_placedTiles.value);
    _WordTile? tile = currentPlaced[index];
    if (tile != null) {
      HapticFeedback.lightImpact();
      currentPlaced[index] = null;
      _placedTiles.value = currentPlaced;

      final currentAvail = List<_WordTile>.from(_availableTiles.value);
      currentAvail.add(tile);
      _availableTiles.value = currentAvail;
    }
  }

  void _clearAll() {
    if (_isSubmitting.value) return;
    _hasError.value = false;

    final currentPlaced = List<_WordTile?>.from(_placedTiles.value);
    final currentAvail = List<_WordTile>.from(_availableTiles.value);

    for (int i = 0; i < currentPlaced.length; i++) {
      final tile = currentPlaced[i];
      if (tile != null) {
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

    String currentSentence = currentPlaced.map((t) => t!.word).join(' ');

    if (currentSentence == _targetSentence) {
      HapticFeedback.mediumImpact();
      _isSubmitting.value = true;
      if (widget.bonusCoins != null && widget.bonusCoins! > 0) {
        context.read<EconomyBloc>().add(
          EconomyAddCoinsRequested(widget.bonusCoins!),
        );
      }
      widget.onConfirmed();
    } else {
      HapticFeedback.heavyImpact();
      _hasError.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0C0C1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final errorColor = Colors.redAccent;

    final content =
        Material(
              type: MaterialType.transparency,
              child: ValueListenableBuilder<bool>(
                valueListenable: _hasError,
                builder: (context, hasError, child) {
                  return Container(
                    padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32.r),
                      ),
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
                                color: widget.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: ValueListenableBuilder<List<_WordTile?>>(
                                valueListenable: _placedTiles,
                                builder: (context, placedTiles, _) {
                                  return Text(
                                    '${placedTiles.length} words',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: widget.primaryColor,
                                      letterSpacing: 1,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        // Clear All button
                        ValueListenableBuilder<bool>(
                          valueListenable: _isSubmitting,
                          builder: (context, isSubmitting, _) {
                            return ValueListenableBuilder<List<_WordTile?>>(
                              valueListenable: _placedTiles,
                              builder: (context, placedTiles, _) {
                                if (placedTiles.any((t) => t != null) &&
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

                        // Placed Tiles (Sentence Builder Area)
                        ValueListenableBuilder<bool>(
                          valueListenable: _hasError,
                          builder: (context, hasError, _) {
                            return ValueListenableBuilder<List<_WordTile?>>(
                              valueListenable: _placedTiles,
                              builder: (context, placedTiles, _) {
                                return Container(
                                      width: double.infinity,
                                      constraints: BoxConstraints(
                                        minHeight: 60.h,
                                      ),
                                      padding: EdgeInsets.all(12.r),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.05,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.02,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        border: Border.all(
                                          color: hasError
                                              ? errorColor.withValues(
                                                  alpha: 0.5,
                                                )
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: Wrap(
                                        spacing: 8.w,
                                        runSpacing: 8.h,
                                        children: List.generate(placedTiles.length, (
                                          index,
                                        ) {
                                          final tile = placedTiles[index];
                                          if (tile == null) {
                                            return Container(
                                              key: ValueKey('empty_$index'),
                                              height: 36.h,
                                              width: 50.w,
                                              decoration: BoxDecoration(
                                                color: widget.primaryColor
                                                    .withValues(alpha: 0.05),
                                                borderRadius:
                                                    BorderRadius.circular(18.r),
                                                border: Border.all(
                                                  color: widget.primaryColor
                                                      .withValues(alpha: 0.2),
                                                  style: BorderStyle.solid,
                                                ),
                                              ),
                                            );
                                          }

                                          return GestureDetector(
                                            key: ValueKey('placed_${tile.id}'),
                                            onTap: () =>
                                                _onPlacedTileTapped(index),
                                            child:
                                                Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 16.w,
                                                            vertical: 8.h,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: widget
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              18.r,
                                                            ),
                                                        border: Border.all(
                                                          color: widget
                                                              .primaryColor
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        tile.word,
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 16.sp,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: textColor,
                                                        ),
                                                      ),
                                                    )
                                                    .animate(
                                                      key: ValueKey(
                                                        'anim_placed_${tile.id}',
                                                      ),
                                                    )
                                                    .scaleXY(
                                                      begin: 0.8,
                                                      end: 1.0,
                                                      curve: Curves.easeOutBack,
                                                      duration: 250.ms,
                                                    ),
                                          );
                                        }),
                                      ),
                                    )
                                    .animate(target: hasError ? 1 : 0)
                                    .shakeX(amount: 5, duration: 400.ms);
                              },
                            );
                          },
                        ),

                        SizedBox(height: 24.h),

                        // Available Tiles (Word Bank)
                        ValueListenableBuilder<List<_WordTile>>(
                          valueListenable: _availableTiles,
                          builder: (context, availableTiles, _) {
                            return Wrap(
                              spacing: 8.w,
                              runSpacing: 12.h,
                              alignment: WrapAlignment.center,
                              children: availableTiles.map((tile) {
                                return GestureDetector(
                                  key: ValueKey('avail_${tile.id}'),
                                  onTap: () => _onAvailableTileTapped(tile),
                                  child:
                                      Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.w,
                                              vertical: 8.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF1E1E2C)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(18.r),
                                              border: Border.all(
                                                color: subtitleColor.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
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
                                );
                              }).toList(),
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
                                return ValueListenableBuilder<List<_WordTile?>>(
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
                                                borderRadius:
                                                    BorderRadius.circular(16.r),
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
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),

                        // Skip button
                        if (widget.allowSkip)
                          ValueListenableBuilder<bool>(
                            valueListenable: _isSubmitting,
                            builder: (context, isSubmitting, _) {
                              if (isSubmitting) return const SizedBox.shrink();
                              return Padding(
                                padding: EdgeInsets.only(top: 16.h),
                                child: ScaleButton(
                                  onTap: () {
                                    if (_isSubmitting.value) return;
                                    _isSubmitting.value = true;
                                    final user = context
                                        .read<AuthBloc>()
                                        .state
                                        .user;
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
                                        onDismissed: () {
                                          if (mounted)
                                            _isSubmitting.value = false;
                                        },
                                      );
                                    }
                                  },
                                  child: Builder(
                                    builder: (context) {
                                      final isPremium =
                                          context
                                              .watch<AuthBloc>()
                                              .state
                                              .user
                                              ?.isPremium ??
                                          false;
                                      return Text(
                                        isPremium
                                            ? 'SKIP'
                                            : 'WATCH AD TO BYPASS',
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
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .animate()
            .slideY(begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOut)
            .fadeIn(duration: 300.ms);

    if (widget.isPositioned) {
      return Positioned(bottom: 0, left: 0, right: 0, child: content);
    }

    return content;
  }
}

class _WordTile {
  final int id;
  final String word;
  _WordTile({required this.id, required this.word});
}
