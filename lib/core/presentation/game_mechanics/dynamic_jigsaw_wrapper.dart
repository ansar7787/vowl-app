import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DynamicJigsawWrapper extends StatefulWidget {
  final String expectedText;
  final Color primaryColor;
  final VoidCallback onConfirmed;
  final VoidCallback onSkipped;
  final int? bonusCoins;
  final bool allowSkip;
  final bool isPositioned;

  const DynamicJigsawWrapper({
    super.key,
    required this.expectedText,
    required this.primaryColor,
    required this.onConfirmed,
    required this.onSkipped,
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

    _WordTile? tile = _placedTiles[index];
    if (tile != null) {
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

    String currentSentence = _placedTiles.map((t) => t!.word).join(' ');

    if (currentSentence == _targetSentence) {
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
                          ],
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
                                    ),
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
