import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DynamicAnagramWrapper extends StatefulWidget {
  final String expectedText;
  final Color primaryColor;
  final VoidCallback onConfirmed;
  final VoidCallback onSkipped;
  final int? bonusCoins;
  final bool allowSkip;

  const DynamicAnagramWrapper({
    super.key,
    required this.expectedText,
    required this.primaryColor,
    required this.onConfirmed,
    required this.onSkipped,
    this.bonusCoins = 5,
    this.allowSkip = true,
  });

  @override
  State<DynamicAnagramWrapper> createState() => _DynamicAnagramWrapperState();
}

class _DynamicAnagramWrapperState extends State<DynamicAnagramWrapper> {
  late List<_Tile> _availableTiles;
  late List<_Tile?> _placedTiles;
  bool _hasError = false;

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
    if (_hasError) setState(() => _hasError = false);

    int emptyIndex = _placedTiles.indexWhere((t) => t == null);
    if (emptyIndex != -1) {
      setState(() {
        _placedTiles[emptyIndex] = tile;
        _availableTiles.remove(tile);
      });
    }
  }

  void _onPlacedTileTapped(int index) {
    if (_hasError) setState(() => _hasError = false);

    _Tile? tile = _placedTiles[index];
    if (tile != null && tile.id != -1) {
      // -1 is a fixed space character
      setState(() {
        _placedTiles[index] = null;
        _availableTiles.add(tile);
      });
    }
  }

  void _onSubmit() {
    if (_placedTiles.contains(null)) {
      setState(() => _hasError = true);
      return;
    }

    String currentWord = _placedTiles.map((t) => t!.letter).join('');
    if (currentWord == widget.expectedText.toUpperCase().trim()) {
      widget.onConfirmed();
    } else {
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

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child:
          Material(
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
                                  Text(
                                    'NOW SPELL IT!',
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
                                    'Tap the letters in the correct order',
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
                                child: Text(
                                  '+${widget.bonusCoins} Coins',
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
                        SizedBox(height: 24.h),

                        // Placed Tiles (Slots)
                        Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              alignment: WrapAlignment.center,
                              children: List.generate(_placedTiles.length, (
                                index,
                              ) {
                                final tile = _placedTiles[index];
                                if (tile != null && tile.id == -1) {
                                  // Render empty space for multi-word answers
                                  return SizedBox(width: 16.w, height: 40.h);
                                }
                                return GestureDetector(
                                  onTap: () => _onPlacedTileTapped(index),
                                  child: Container(
                                    width: 40.w,
                                    height: 48.h,
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
                                        ? Text(
                                            tile.letter,
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          )
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
                          spacing: 8.w,
                          runSpacing: 8.h,
                          alignment: WrapAlignment.center,
                          children: _availableTiles.map((tile) {
                            return GestureDetector(
                              onTap: () => _onAvailableTileTapped(tile),
                              child: Container(
                                width: 40.w,
                                height: 48.h,
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
                                child: Text(
                                  tile.letter,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        SizedBox(height: 32.h),

                        // Controls
                        Row(
                          children: [
                            if (widget.allowSkip) ...[
                              Expanded(
                                flex: 1,
                                child: TextButton(
                                  onPressed: widget.onSkipped,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                  ),
                                  child: Text(
                                    'Skip',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: subtitleColor,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                            ],
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _onSubmit,
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
                      ],
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
              .fadeIn(duration: 300.ms),
    );
  }
}

class _Tile {
  final int id;
  final String letter;
  _Tile({required this.id, required this.letter});
}
