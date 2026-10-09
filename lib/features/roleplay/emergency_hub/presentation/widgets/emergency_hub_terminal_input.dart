import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color07070f = Color(0xFF07070F);
}

class EmergencyHubTerminalInput extends StatefulWidget {
  final TextEditingController controller;
  final String correctAnswer;
  final bool isDark;
  final VoidCallback onChanged;

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
    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: widget.isDark
            ? _LocalPalette.color07070f
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.03),
        ),
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
                  fontSize: 10.sp,
                  color: Colors.amberAccent,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.keyboard_rounded,
                color: Colors.amberAccent,
                size: 16.r,
              ),
            ],
          ),
          SizedBox(height: 12.h),

          TextField(
            controller: widget.controller,
            readOnly:
                true, // Prevent manual typing to force using the jumbled chips
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              color: widget.isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
            decoration: InputDecoration(
              hintText: "Select words to build broadcast",
              hintStyle: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                color: widget.isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 1.0,
              ),
              filled: true,
              fillColor: widget.isDark ? AppColors.deepDark : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: widget.isDark ? Colors.white12 : Colors.black12,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: Colors.amberAccent.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              prefixIcon: Icon(
                Icons.terminal_rounded,
                color: Colors.amberAccent,
                size: 20.r,
              ),
              suffixIcon: _selectedIndices.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.backspace_rounded,
                        color: Colors.grey,
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
          Wrap(
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
                                : Colors.white),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (widget.isDark ? Colors.white24 : Colors.black26),
                      ),
                      boxShadow: isSelected
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Text(
                      _shuffledWords[index],
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? (widget.isDark ? Colors.white38 : Colors.black38)
                            : (widget.isDark ? Colors.white : Colors.black87),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }
}
