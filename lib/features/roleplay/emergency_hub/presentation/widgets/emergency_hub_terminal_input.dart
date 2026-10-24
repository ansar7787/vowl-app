import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color07070f = Color(0xFF07070F);
}

/// Terminal text and tile response composer for emergency communications.
class EmergencyHubTerminalInput extends StatefulWidget {
  /// Editing controller holding the constructed response string.
  final TextEditingController controller;

  /// Expected correct answer phrase.
  final String correctAnswer;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Callback fired when the input changes.
  final VoidCallback onChanged;

  /// Creates an [EmergencyHubTerminalInput] widget.
  const EmergencyHubTerminalInput({
    super.key,
    required this.controller,
    required this.correctAnswer,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<EmergencyHubTerminalInput> createState() =>
      _EmergencyHubTerminalInputState();
}

class _EmergencyHubTerminalInputState extends State<EmergencyHubTerminalInput> {
  List<String> _shuffledWords = [];
  List<int> _selectedIndices = [];

  @override
  void initState() {
    super.initState();
    _initWords();
  }

  @override
  void didUpdateWidget(covariant EmergencyHubTerminalInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.correctAnswer != widget.correctAnswer) {
      _initWords();
    }
  }

  void _initWords() {
    final words = widget.correctAnswer
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    // Add distractors if needed, but for simplicity let's just jumble the correct words
    words.shuffle();
    _shuffledWords = words;
    _selectedIndices = [];

    // Attempt to sync controller if it already has text
    if (widget.controller.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.controller.clear();
          widget.onChanged();
        }
      });
    }
  }

  void _toggleWord(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
      widget.controller.text = _selectedIndices
          .map((i) => _shuffledWords[i])
          .join(' ');
      widget.onChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    Widget chipsWrap = Wrap(
      key: const Key('emergency_hub_word_chips_wrap'),
      spacing: 8.w,
      runSpacing: 8.h,
      alignment: WrapAlignment.center,
      children: List.generate(_shuffledWords.length, (index) {
        final isSelected = _selectedIndices.contains(index);
        return Semantics(
          button: true,
          label: _shuffledWords[index],
          hint: isSelected
              ? "Double tap to remove word from terminal"
              : "Double tap to add word to terminal",
          child: GestureDetector(
            key: Key('emergency_hub_word_chip_$index'),
            onTap: () => _toggleWord(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 10.h,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? (widget.isDark ? Colors.white12 : Colors.black12)
                    : (widget.isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (widget.isDark ? Colors.white24 : Colors.black12),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Text(
                _shuffledWords[index],
                key: Key('emergency_hub_word_chip_text_$index'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? (widget.isDark ? Colors.white38 : Colors.black38)
                      : (widget.isDark ? Colors.white : Colors.black87),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        );
      }),
    );

    if (!reduceMotion) {
      chipsWrap = chipsWrap.animate().fadeIn(
        duration: 400.ms,
        curve: Curves.easeOut,
      );
    }

    final accentColor =
        widget.isDark ? Colors.amberAccent : Colors.amber.shade900;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: widget.isDark
            ? _LocalPalette.color07070f
            : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: widget.isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "INPUT TERMINAL",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: accentColor,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.keyboard_rounded,
                color: accentColor,
                size: 18.r,
              ),
            ],
          ),
          SizedBox(height: 12.h),

          TextField(
            key: const Key('emergency_hub_terminal_text_field'),
            controller: widget.controller,
            readOnly:
                true, // Prevent manual typing to force using the jumbled chips
            maxLines: null,
            minLines: 1,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              color: widget.isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: "Select words to build broadcast",
              hintStyle: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                color: widget.isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 0.3,
              ),
              filled: true,
              fillColor: widget.isDark
                  ? AppColors.deepDark
                  : const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: widget.isDark ? Colors.white12 : Colors.black12,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: widget.isDark ? Colors.white12 : Colors.black12,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: accentColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              prefixIcon: Icon(
                Icons.terminal_rounded,
                color: accentColor,
                size: 20.r,
              ),
              suffixIcon: _selectedIndices.isNotEmpty
                  ? IconButton(
                      key: const Key('emergency_hub_backspace_button'),
                      icon: Icon(
                        Icons.backspace_rounded,
                        color: widget.isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                        size: 20.r,
                      ),
                      onPressed: () {
                        if (_selectedIndices.isNotEmpty) {
                          _toggleWord(_selectedIndices.last);
                        }
                      },
                    )
                  : null,
            ),
          ),

          SizedBox(height: 16.h),
          chipsWrap,
        ],
      ),
    );
  }
}
