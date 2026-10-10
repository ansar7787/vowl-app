import re

with open('lib/features/kids_zone/presentation/widgets/layouts/kids_alphabet_layout.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
import_stmt = "import 'package:vowl/core/utils/custom_snack_bar.dart';\n"
content = content.replace("import 'package:vowl/core/theme/app_colors.dart';\n", "import 'package:vowl/core/theme/app_colors.dart';\n" + import_stmt)

# Replace class
class_pattern = re.compile(r'class _KidsChalkboardState extends State<_KidsChalkboard> \{.*\}', re.DOTALL)

new_class = '''class _KidsChalkboardState extends State<_KidsChalkboard> {
  bool _isRevealedLocally = false;

  @override
  void didUpdateWidget(covariant _KidsChalkboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quest != widget.quest) {
      _isRevealedLocally = false;
    }
  }

  Future<void> _playTTS(String text) async {
    final success = await di.sl<KidsTTSService>().speak(text, force: true);
    if (!success && mounted) {
      CustomSnackBar.show(
        context: context,
        message: context.tr('errors.tts_failed', fallback: 'Audio not available right now.'),
        type: CustomSnackBarType.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        if (widget.state.answerStatus.isAnswered) return;
        final text = details.data;
        final isCorrect = (text == widget.quest.correctAnswer);
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final shouldReveal = widget.state.answerStatus == AnswerStatus.correct || widget.state.isFinalFailure || _isRevealedLocally;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 320.w,
          height: 220.h,
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isHovering
                ? _LocalPalette.color2d6a4f
                : _LocalPalette.color1b4332,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isHovering
                  ? _LocalPalette.colorb07d45
                  : _LocalPalette.color8b5a2b,
              width: 12.r,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              if (!shouldReveal) {
                setState(() {
                  _isRevealedLocally = true;
                });
              }
            },
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  );
                },
                child: !shouldReveal
                    ? _buildUnrevealedState(context, widget.quest)
                    : _buildRevealedState(context, widget.quest),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Helper to highlight the target letter in the word to teach phonetic connection
  List<TextSpan> _buildHighlightedWordSpans(
    String word,
    String? correctAnswer,
  ) {
    if (correctAnswer == null || correctAnswer.isEmpty) {
      return [
        TextSpan(
          text: word,
          style: const TextStyle(color: _LocalPalette.colora7f3d0),
        ),
      ];
    }

    if (word.toLowerCase().startsWith(correctAnswer.toLowerCase())) {
      final firstPart = word.substring(0, correctAnswer.length);
      final restPart = word.substring(correctAnswer.length);
      return [
        TextSpan(
          text: firstPart,
          style: const TextStyle(
            color: _LocalPalette.colorfcd34d,
            fontWeight: FontWeight.w700,
          ), // Highlight Yellow
        ),
        TextSpan(
          text: restPart,
          style: const TextStyle(
            color: _LocalPalette.colora7f3d0,
          ), // Chalk mint
        ),
      ];
    }
    return [
      TextSpan(
        text: word,
        style: const TextStyle(color: _LocalPalette.colora7f3d0),
      ),
    ];
  }

  Widget _buildUnrevealedState(BuildContext context, dynamic quest) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        key: const ValueKey('unrevealed'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.help_outline_rounded,
            size: 64.sp,
            color: _LocalPalette.colorfde68a.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: _LocalPalette.colorfde68a,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: Offset(0, 4.h),
                  blurRadius: 4,
                ),
              ],
            ),
            child: KidsFittedText(
              context.tr('games.kids_tap_clue', fallback: 'Tap for clue'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.amber900,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealedState(BuildContext context, dynamic quest) {
    return Padding(
      key: const ValueKey('revealed'),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 280.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if ((quest.wordEmoji ?? quest.emoji) != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Text(
                    (quest.wordEmoji ?? quest.emoji)!,
                    style: TextStyle(fontSize: 72.sp),
                  ),
                ),
              if (quest.wordExample != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            ..._buildHighlightedWordSpans(
                              quest.wordExample!,
                              quest.correctAnswer,
                            ),
                            if (quest.phonetic != null)
                              TextSpan(
                                text: ' (/${quest.phonetic}/)',
                                style: const TextStyle(
                                  color: _LocalPalette.colorfcd34d,
                                ),
                              ),
                          ],
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24.r),
                        onTap: () {
                          String? textToRead;
                          if (quest.wordExample != null) {
                            textToRead = quest.wordExample;
                          } else if (InstructionHelper.getInstruction(quest).isNotEmpty) {
                            textToRead = InstructionHelper.getInstruction(quest);
                          } else if (quest.question != null) {
                            textToRead = quest.question;
                          }
                          if (textToRead != null) {
                            _playTTS(textToRead);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: _LocalPalette.colorfde68a.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.volume_up_rounded,
                            size: 28.sp,
                            color: _LocalPalette.colorfde68a,
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
    );
  }
}'''

content = class_pattern.sub(new_class, content)

with open('lib/features/kids_zone/presentation/widgets/layouts/kids_alphabet_layout.dart', 'w', encoding='utf-8') as f:
    f.write(content)
