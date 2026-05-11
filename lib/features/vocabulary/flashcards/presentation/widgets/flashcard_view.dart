import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class FlashcardView extends StatelessWidget {
  final bool isFlipped;
  final bool showHint;
  final dynamic quest;
  final String definition;
  final ThemeResult theme;
  final bool isDark;
  final int hintCount;
  final VoidCallback onFlip;
  final VoidCallback onHintToggle;

  const FlashcardView({
    super.key,
    required this.isFlipped,
    required this.showHint,
    required this.quest,
    required this.definition,
    required this.theme,
    required this.isDark,
    required this.hintCount,
    required this.onFlip,
    required this.onHintToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onFlip,
        child: Container(
          width: 0.85.sw,
          height: 0.5.sh,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32.r),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: -10,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                children: <Widget>[
                  ...previousChildren,
                  currentChild ?? const SizedBox.shrink(),
                ],
              );
            },
            transitionBuilder: (child, animation) {
              final rotate = Tween<double>(begin: 3.1415, end: 0.0).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ));

              return AnimatedBuilder(
                animation: rotate,
                child: child,
                builder: (context, child) {
                  final isUnder = (ValueKey(isFlipped) != child!.key);
                  double value = isUnder ? rotate.value : (rotate.value - 3.1415).abs();
                  
                  final bool isBack = value > (3.1415 / 2);
                  final Matrix4 matrix = Matrix4.identity()
                    ..setEntry(3, 2, 0.0012);
                  
                  if (isBack) {
                    matrix.rotateY(value + 3.1415);
                  } else {
                    matrix.rotateY(value);
                  }

                  return Transform(
                    transform: matrix,
                    alignment: Alignment.center,
                    child: child,
                  );
                },
              );
            },
            child: isFlipped
                ? _buildCardSide(
                    key: const ValueKey(true),
                    title: 'MEANING',
                    content: definition,
                    secondaryContent: (quest.contextSentence != quest.word && quest.contextSentence != quest.transcript) 
                        ? quest.contextSentence 
                        : null,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    textColor: isDark ? Colors.white : Colors.black87,
                    isBackSide: true,
                  )
                : _buildCardSide(
                    key: const ValueKey(false),
                    title: 'VOCABULARY',
                    content: quest.word ?? quest.transcript ?? 'Unknown',
                    color: theme.primaryColor,
                    textColor: Colors.white,
                    isBackSide: false,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardSide({
    required Key key,
    required String title,
    required String content,
    String? secondaryContent,
    required Color color,
    required Color textColor,
    required bool isBackSide,
  }) {
    return GlassTile(
      key: key,
      color: color,
      borderRadius: BorderRadius.circular(32.r),
      child: Container(
        padding: EdgeInsets.all(30.r),
        width: double.infinity,
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                color: textColor.withValues(alpha: 0.5),
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            
            // Main Content
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                content,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: isBackSide ? 24.sp : 42.sp,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  height: 1.1,
                ),
              ),
            ),
            
            if (isBackSide && secondaryContent != null) ...[
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: textColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Text(
                      'EXAMPLE',
                      style: GoogleFonts.outfit(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: textColor.withValues(alpha: 0.4),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      secondaryContent,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const Spacer(),

            // Interactive Controls at bottom of card
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isBackSide && quest.hint != null)
                  ScaleButton(
                    onTap: onHintToggle,
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            showHint ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                            color: Colors.white,
                            size: 20.r,
                          ),
                          if (!showHint) ...[
                            SizedBox(width: 4.w),
                            Text(
                              "$hintCount",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                if (!isBackSide && quest.hint != null) SizedBox(width: 20.w),
                ScaleButton(
                  onTap: () {
                    di.sl<TtsService>().speak(quest.word ?? quest.transcript ?? 'Vocabulary');
                  },
                  child: Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: !isBackSide ? Colors.white24 : theme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: !isBackSide ? Colors.white30 : theme.primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: !isBackSide ? Colors.white : theme.primaryColor,
                      size: 24.r,
                    ),
                  ),
                ),
              ],
            ),
            
            // Hint Display
            if (showHint && !isBackSide)
              Container(
                margin: EdgeInsets.only(top: 20.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  quest.hint!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
