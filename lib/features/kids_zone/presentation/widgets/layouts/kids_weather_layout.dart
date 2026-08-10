import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';

/// Sky Theme for Weather Game
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
            // The Sky Billboard
            Expanded(
              flex: 6,
              child: Center(child: _buildSkyBillboard(context, state, quest)),
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

  Widget _buildSkyBillboard(
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
          onTap: state.lastAnswerCorrect != null
              ? null
              : () {
                  if (quest.instruction != null) {
                    di.sl<KidsTTSService>().speak(quest.instruction!);
                  }
                },
          child: Container(
            width: 320.w,
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isHovering
                      ? const Color(0xFFE0F2FE)
                      : const Color(0xFFF0F9FF), // Sky 50
                  isHovering
                      ? const Color(0xFFBAE6FD)
                      : const Color(0xFFE0F2FE), // Sky 100
                ],
              ),
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(
                color: isHovering
                    ? const Color(0xFF38BDF8)
                    : const Color(0xFFBAE6FD),
                width: isHovering ? 6 : 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF38BDF8,
                  ).withValues(alpha: isHovering ? 0.4 : 0.2),
                  blurRadius: isHovering ? 25 : 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (quest.emoji != null &&
                        (quest.question == "?" || quest.question == null))
                      state.lastAnswerCorrect == true
                          ? Text(
                              quest.emoji!,
                              style: TextStyle(fontSize: 80.sp),
                            )
                          : ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                const Color(0xFF0369A1).withValues(alpha: 0.3),
                                BlendMode.srcIn,
                              ),
                              child: Text(
                                quest.emoji!,
                                style: TextStyle(fontSize: 80.sp),
                              ),
                            ),
                    if (state.lastAnswerCorrect != true ||
                        (quest.question != "?" && quest.question != null))
                      KidsFittedText(
                        quest.question ?? "?",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize:
                              (quest.question == "?" || quest.question == null)
                              ? 70.sp
                              : 32.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0369A1).withValues(
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
                  ],
                ),
                if (quest.phonetic != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    quest.phonetic!,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7DD3FC),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                if (quest.wordExample != null) ...[
                  SizedBox(height: 12.h),
                  KidsFittedText(
                    '"${quest.wordExample!}"',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0C4A6E),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              ],
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
    final cloudWidget = Container(
      width: 120.w,
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Color(0xFFF0F9FF), // Very soft blue at bottom of cloud
          ],
        ),
        borderRadius: BorderRadius.circular(40.r), // Cloud-like pill shape
        border: Border.all(color: const Color(0xFFE0F2FE), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7DD3FC).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
              child: KidsFittedText(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0369A1),
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
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
