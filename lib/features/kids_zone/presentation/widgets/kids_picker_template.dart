import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_image.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:auto_size_text/auto_size_text.dart';

class KidsPickerTemplate extends StatefulWidget {
  final String title;
  final String gameType;
  final int level;
  final Color primaryColor;
  final List<Color> backgroundColors;
  final IconData fallbackIcon;
  final String? centerTextOverride;
  final String? painterName;
  final String? shaderName;

  const KidsPickerTemplate({
    super.key,
    required this.title,
    required this.gameType,
    required this.level,
    required this.primaryColor,
    required this.backgroundColors,
    required this.fallbackIcon,
    this.centerTextOverride,
    this.painterName,
    this.shaderName,
  });

  @override
  State<KidsPickerTemplate> createState() => _KidsPickerTemplateState();
}

class _KidsPickerTemplateState extends State<KidsPickerTemplate> {
  bool _isOverTarget = false;

  @override
  Widget build(BuildContext context) {
    String effectivePainter = widget.painterName ?? "KidsWorldBackground";
    if (effectivePainter.isEmpty) effectivePainter = "KidsWorldBackground";

    return KidsGameBaseScreen(
      title: widget.title,
      gameType: widget.gameType,
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: widget.backgroundColors,
      painterName: effectivePainter,
      shaderName: widget.shaderName,
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            // Extra space at the top to accommodate the Mascot + Speech Bubble injected by KidsGameBaseScreen
            SizedBox(height: 120.h),

            Expanded(
              flex: 5,
              child: Center(child: _buildDragTarget(context, state, quest)),
            ),

            Flexible(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.only(bottom: 40.h, left: 16.w, right: 16.w),
                child: Center(child: _buildOptions(context, state, quest)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDragTarget(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
  ) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isOverTarget = true);
        return state.answerStatus == AnswerStatus.unanswered;
      },
      onLeave: (data) => setState(() => _isOverTarget = false),
      onAcceptWithDetails: (details) {
        setState(() => _isOverTarget = false);
        final option = details.data;
        final isCorrect = quest.correctAnswer == option;
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: 300.ms,
          transform: Matrix4.diagonal3Values(
            _isOverTarget ? 1.05 : 1.0,
            _isOverTarget ? 1.05 : 1.0,
            1.0,
          ),
          child: _buildCentralVisual(quest, isHighlighted: _isOverTarget),
        );
      },
    );
  }

  Widget _buildCentralVisual(KidsQuest quest, {bool isHighlighted = false}) {
    final displayValue = widget.centerTextOverride ?? quest.question ?? "?";
    final isEmoji = _isEmoji(displayValue);
    final hasImage = quest.imageUrl != null && quest.imageUrl!.isNotEmpty;

    return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Solid, high-contrast circle
            Container(
              width: 200.r,
              height: 200.r,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isHighlighted
                      ? widget.primaryColor
                      : widget.primaryColor.withValues(alpha: 0.3),
                  width: isHighlighted ? 8 : 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(
                      alpha: isHighlighted ? 0.3 : 0.15,
                    ),
                    blurRadius: isHighlighted ? 30 : 15,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(hasImage ? 25.r : 20.r),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: hasImage
                        ? SizedBox(
                            width: 140.r,
                            height: 140.r,
                            child: KidsImage(
                              imageUrl: quest.imageUrl,
                              fallbackIcon: widget.fallbackIcon,
                              iconColor: widget.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          )
                        : Text(
                            displayValue,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: _getCentralFontSize(
                                displayValue,
                                isEmoji,
                              ),
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1E293B),
                              letterSpacing: isEmoji ? 4 : 0,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                          ),
                  ),
                ),
              ),
            ),

            if (isHighlighted)
              Positioned(
                bottom: -15.h,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: widget.primaryColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    context.tr('games.kids_drop_here', fallback: 'Drop here'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ).animate().fadeIn().scale(),
              ),
          ],
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut);
  }

  Widget _buildOptions(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
  ) {
    final options = quest.options ?? [];

    return Wrap(
      spacing: 16.w,
      runSpacing: 20.h,
      alignment: WrapAlignment.center,
      children: List.generate(options.length, (index) {
        final option = options[index];
        final isCorrect = quest.correctAnswer == option;
        final isAnswered = state.answerStatus.isAnswered;

        // 50/50 Lifeline Logic
        bool isRemovedByHint = false;
        if (state.hintUsed && !isCorrect && options.length > 2) {
          final distractors = options
              .where((o) => o != quest.correctAnswer)
              .toList();
          if (option != distractors.first) {
            isRemovedByHint = true;
          }
        }

        final optionWidget = _buildOptionCard(option, isAnswered);

        Widget childWidget =
            Draggable<String>(
                  data: option,
                  maxSimultaneousDrags: (isAnswered || isRemovedByHint) ? 0 : 1,
                  feedback: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: 140.w,
                      child: _buildOptionCard(option, false, isFeedback: true),
                    ),
                  ),
                  childWhenDragging: Opacity(opacity: 0.3, child: optionWidget),
                  child: ScaleButton(
                    onTap: (isAnswered || isRemovedByHint)
                        ? null
                        : () {
                            di.sl<KidsTTSService>().speak(option);
                            context.read<KidsBloc>().add(
                              SubmitKidsAnswer(isCorrect),
                            );
                          },
                    child: optionWidget,
                  ),
                )
                .animate()
                .scale(
                  delay: (index * 100).ms,
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                )
                .slideY(begin: 0.2, end: 0);

        if (isRemovedByHint) {
          return AnimatedOpacity(
            duration: 500.ms,
            opacity: 0.0,
            child: AnimatedScale(
              duration: 500.ms,
              scale: 0.5,
              curve: Curves.easeOutCubic,
              child: IgnorePointer(child: childWidget),
            ),
          );
        }

        return childWidget;
      }),
    );
  }

  Widget _buildOptionCard(
    String option,
    bool isAnswered, {
    bool isFeedback = false,
  }) {
    return Container(
      constraints: BoxConstraints(minWidth: 120.w),
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isFeedback ? widget.primaryColor : Colors.grey.shade300,
          width: isFeedback ? 3 : 2,
        ),
        // Chunky 3D Duolingo-style bottom shadow
        boxShadow: [
          if (!isFeedback)
            BoxShadow(color: Colors.grey.shade300, offset: const Offset(0, 6)),
        ],
      ),
      child: AutoSizeText(
        option,
        maxLines: 2,
        minFontSize: 12,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: _getOptionFontSize(option),
          fontWeight: FontWeight.w800,
          color: const Color(0xFF334155),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  double _getCentralFontSize(String text, bool isEmoji) {
    if (!isEmoji) return 110.sp;
    int count = text.runes.length;
    if (count <= 1) return 90.sp;
    if (count <= 2) return 65.sp;
    if (count <= 3) return 50.sp;
    if (count <= 5) return 40.sp;
    return 30.sp;
  }

  bool _isEmoji(String text) {
    if (text.isEmpty) return false;
    return text.runes.any((rune) => rune > 128);
  }

  double _getOptionFontSize(String text) {
    if (_isEmoji(text)) {
      int count = text.runes.length;
      if (count <= 1) return 45.sp;
      if (count <= 3) return 35.sp;
      return 28.sp;
    }
    if (text.length <= 2) return 36.sp;
    if (text.length > 12) return 18.sp;
    return 24.sp;
  }
}


