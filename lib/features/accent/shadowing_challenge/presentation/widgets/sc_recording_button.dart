import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:voxai_quest/core/presentation/themes/level_theme_helper.dart';
import 'package:voxai_quest/core/presentation/widgets/glass_tile.dart';

class SCRecordingButton extends StatelessWidget {
  final bool isListening;
  final bool isDark;
  final ThemeResult theme;
  final String recognizedText;
  final String targetSentence;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;

  const SCRecordingButton({
    super.key,
    required this.isListening,
    required this.isDark,
    required this.theme,
    required this.recognizedText,
    required this.targetSentence,
    required this.onStartListening,
    required this.onStopListening,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (recognizedText.isNotEmpty) ...[
          StreamBuilder<String>(
            stream: Stream.value(recognizedText),
            builder: (context, snapshot) {
              return GlassTile(
                padding: EdgeInsets.all(20.r),
                color: theme.primaryColor.withValues(alpha: 0.1),
                child: _buildHighlightedRecognizedText(recognizedText, isDark),
              );
            },
          ).animate().fadeIn(),
          SizedBox(height: 40.h),
        ],
        _buildEchoAuraButton(),
        SizedBox(height: 16.h),
        Text(
          isListening ? "RELEASE TO SUBMIT" : "HOLD TO SHADOW",
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white38 : Colors.black38,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildEchoAuraButton() {
    return GestureDetector(
      onTapDown: (_) => onStartListening(),
      onTapUp: (_) => onStopListening(),
      onTapCancel: () => onStopListening(),
      child: RepaintBoundary(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Base spacing box
            SizedBox(width: 150.r, height: 150.r),

            // The Echo Aura Layers
            if (isListening)
              ...List.generate(3, (index) {
                return Container(
                      width: 100.r,
                      height: 100.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withValues(
                          alpha: 0.3 - (index * 0.1),
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .scale(
                      begin: const Offset(1, 1),
                      end: Offset(1.5 + (index * 0.3), 1.5 + (index * 0.3)),
                      duration: (1000 + index * 200).ms,
                      curve: Curves.easeOut,
                    )
                    .fadeOut(duration: (1000 + index * 200).ms);
              }),

            // Core Button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isListening ? 110.r : 100.r,
              height: isListening ? 110.r : 100.r,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: isListening
                      ? [Colors.white, theme.primaryColor]
                      : [
                          theme.primaryColor.withValues(alpha: 0.8),
                          theme.primaryColor.withValues(alpha: 0.4),
                        ],
                  center: Alignment.topLeft,
                  radius: 1.5,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isListening
                      ? Colors.white
                      : theme.primaryColor.withValues(alpha: 0.6),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(
                      alpha: isListening ? 0.6 : 0.3,
                    ),
                    blurRadius: isListening ? 30 : 15,
                    spreadRadius: isListening ? 10 : 0,
                  ),
                ],
              ),
              child: Icon(
                Icons.mic_rounded,
                color: isListening ? theme.primaryColor : Colors.white,
                size: isListening ? 52.r : 48.r,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildHighlightedRecognizedText(String text, bool isDark) {
    if (text.isEmpty) return const SizedBox.shrink();

    final targetWords = targetSentence
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ');
    final recognizedWords = text.split(' ');

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      children: recognizedWords.map((word) {
        final cleanWord = word.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
        final bool isMatch = targetWords.contains(cleanWord);

        return Text(
          word,
          style: GoogleFonts.outfit(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: isMatch
                ? (isDark ? theme.primaryColor : Colors.green)
                : Colors.redAccent,
            decoration: isMatch ? null : TextDecoration.lineThrough,
            decorationThickness: 2,
          ),
        );
      }).toList(),
    );
  }
}
