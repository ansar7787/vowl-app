import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';

/// Immersive Sky Window Theme for Weather Game
class KidsWeatherLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsWeatherLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'weather',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 60.h),
            // The Weather Window (Target)
            Expanded(
              flex: 6,
              child: Center(child: _buildWeatherWindow(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            KidsFittedText(
              context.tr(
                'games.kids_weather_drag',
                fallback: 'Drag the weather cloud to the sky! ✨',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            // The Weather Clouds (Options)
            Flexible(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16.w,
                  runSpacing: 16.h,
                  children: List.generate(quest.options?.length ?? 0, (index) {
                    final option = quest.options![index];
                    return _buildWeatherCloud(
                      context,
                      state,
                      option,
                      quest.correctAnswer == option,
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeatherWindow(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
  ) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final text = details.data;
        final isCorrect = (text == quest.correctAnswer);
        if (!isCorrect) {
          di.sl<KidsTTSService>().speak(text);
        }
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return InkWell(
          onTap: state.answerStatus.isAnswered
              ? null
              : () {
                  if (InstructionHelper.getInstruction(quest).isNotEmpty) {
                    di.sl<KidsTTSService>().speak(
                      InstructionHelper.getInstruction(quest),
                    );
                  }
                },
          child: Container(
            width: 320.w,
            height: 240.h,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5A2B), // Wooden brown outer frame
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isHovering ? Colors.yellow : const Color(0xFF5C3A21),
                width: isHovering ? 8 : 6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              margin: EdgeInsets.all(12.r),
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF87CEEB), // Sky blue
                    Color(0xFFE0F6FF), // Lighter sky
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Window crossbars
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 8.h,
                      color: const Color(0xFF8B5A2B),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 8.w,
                      height: double.infinity,
                      color: const Color(0xFF8B5A2B),
                    ),
                  ),
                  // Curtains
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 40.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444), // Red curtains
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(30.r),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 40.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444), // Red curtains
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(30.r),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(-2, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // The riddle / emoji
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (quest.emoji != null &&
                            (quest.question == "?" || quest.question == null))
                          state.answerStatus == AnswerStatus.correct
                              ? Text(
                                  quest.emoji!,
                                  style: TextStyle(fontSize: 80.sp),
                                )
                              : ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    const Color(
                                      0xFF0369A1,
                                    ).withValues(alpha: 0.4),
                                    BlendMode.srcIn,
                                  ),
                                  child: Text(
                                    quest.emoji!,
                                    style: TextStyle(fontSize: 80.sp),
                                  ),
                                ),
                        if (state.answerStatus != AnswerStatus.correct ||
                            (quest.question != "?" && quest.question != null))
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: KidsFittedText(
                              quest.question ?? "?",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize:
                                    (quest.question == "?" ||
                                        quest.question == null)
                                    ? 80.sp
                                    : 32.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0C4A6E).withValues(
                                  alpha:
                                      (quest.question == "?" ||
                                          quest.question == null)
                                      ? 0.7
                                      : 1.0,
                                ),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 6,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherCloud(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    final cloudWidget = SizedBox(
      width: 140.w,
      height: 90.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base pill (Bottom of cloud)
          Positioned(
            bottom: 10.h,
            child: Container(
              width: 130.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF93C5FD).withValues(alpha: 0.5),
                    offset: const Offset(0, 6),
                    blurRadius: 0, // Hard shadow for cartoon style
                  ),
                ],
              ),
            ),
          ),
          // Top left puff
          Positioned(
            left: 20.w,
            bottom: 25.h,
            child: Container(
              width: 50.w,
              height: 50.w,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Top right puff
          Positioned(
            right: 25.w,
            bottom: 20.h,
            child: Container(
              width: 60.w,
              height: 60.w,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Text on top
          Positioned(
            bottom: 22.h,
            child: SizedBox(
              width: 110.w,
              child: KidsFittedText(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0369A1),
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(opacity: 0.9, child: cloudWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: cloudWidget),
      child: cloudWidget,
    );
  }
}
