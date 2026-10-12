import 'package:vowl/core/theme/app_colors.dart';
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
import 'package:flutter_svg/flutter_svg.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color colorfef2f2 = Color(0xFFFEF2F2);
  static const Color colord4d4d8 = Color(0xFFD4D4D8);
  static const Color colore4e4e7 = Color(0xFFE4E4E7);
}

/// Chef's Kitchen Theme for Food Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsFoodLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsFoodLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'food',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: KidsGameBaseScreen.mascotClearanceHeight),
            // The Chef's Hat / Board
            Expanded(
              flex: 5,
              child: Center(child: _buildKitchenBoard(context, state, quest)),
            ),
            SizedBox(height: 16.h),
            KidsFittedText(
              context.tr(
                'games.kids_food_drag',
                fallback: 'Drag the right food to the board!',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.black.withValues(alpha: 0.7),
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            // Serving Platters (Options)
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Checkered Tablecloth
                  Container(
                    height: 50.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8.r),
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: SvgPicture.string(
                      _checkeredTableclothSvg,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 24.h,
                      left: 12.w,
                      right: 12.w,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(quest.options?.length ?? 0, (
                        index,
                      ) {
                        final option = quest.options![index];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: _buildServingPlatterOption(
                              context,
                              state,
                              option,
                              quest.correctAnswer == option,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKitchenBoard(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardWidth = constraints.maxWidth > 0
            ? (constraints.maxWidth * 0.9).clamp(200.0, 400.0)
            : 280.w;
        final double boardHeight = constraints.maxHeight > 0
            ? (constraints.maxHeight * 0.9).clamp(150.0, 220.0)
            : 200.h;

        return DragTarget<String>(
          onWillAcceptWithDetails: (details) => !state.answerStatus.isAnswered,
          onAcceptWithDetails: (details) {
            _handleAnswer(context, state, quest, details.data);
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
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  // The White Kitchen Tile Board
                  Container(
                    width: boardWidth,
                    height: boardHeight,
                    decoration: BoxDecoration(
                      color: isHovering
                          ? _LocalPalette.colorfef2f2
                          : Colors.white, // Light red tint on hover
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isHovering
                            ? AppColors.rose700
                            : _LocalPalette.colord4d4d8,
                        width: isHovering ? 6.r : 4.r,
                      ), // Light grey tile border
                      boxShadow: [
                        BoxShadow(
                          color: isHovering
                              ? AppColors.rose700.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.1),
                          blurRadius: isHovering ? 20 : 10,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (quest.emoji != null &&
                                    (quest.question == "?" ||
                                        quest.question == null))
                                  state.answerStatus == AnswerStatus.correct
                                      ? Text(
                                          quest.emoji!,
                                          style: TextStyle(fontSize: 70.sp),
                                        )
                                      : ColorFiltered(
                                          colorFilter: const ColorFilter.mode(
                                            AppColors.slate300,
                                            BlendMode.srcIn,
                                          ),
                                          child: Text(
                                            quest.emoji!,
                                            style: TextStyle(fontSize: 70.sp),
                                          ),
                                        ),
                                if (state.answerStatus !=
                                        AnswerStatus.correct ||
                                    (quest.question != "?" &&
                                        quest.question != null))
                                  KidsFittedText(
                                    quest.question ?? "?",
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize:
                                          (quest.question == "?" ||
                                              quest.question == null)
                                          ? 60.sp
                                          : 24.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.rose700.withValues(
                                        alpha:
                                            (quest.question == "?" ||
                                                quest.question == null)
                                            ? 0.7
                                            : 1.0,
                                      ),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // A cute chef hat resting on top
                  Positioned(
                    top: -(boardHeight * 0.15).clamp(20.0, 40.0),
                    child: Container(
                      width: (boardWidth * 0.28).clamp(60.0, 90.0),
                      height: (boardHeight * 0.2).clamp(30.0, 50.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(40.r),
                        ),
                        border: Border.all(
                          color: _LocalPalette.colore4e4e7,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            width: 2.w,
                            height: 20.h,
                            color: _LocalPalette.colore4e4e7,
                          ),
                          Container(
                            width: 2.w,
                            height: 25.h,
                            color: _LocalPalette.colore4e4e7,
                          ),
                          Container(
                            width: 2.w,
                            height: 20.h,
                            color: _LocalPalette.colore4e4e7,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleAnswer(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
    String text,
  ) {
    if (state.answerStatus.isAnswered) return;
    final isCorrect = (text == quest.correctAnswer);
    final parts = text.trim().split(' ');
    final cleanText = parts.length > 1
        ? parts.sublist(0, parts.length - 1).join(' ')
        : text;
    di.sl<KidsTTSService>().speak(cleanText);
    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  Widget _buildServingPlatterOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    final parts = text.trim().split(' ');
    String namePart = text;
    String emojiPart = '';
    if (parts.length > 1) {
      emojiPart = parts.last;
      namePart = parts.sublist(0, parts.length - 1).join(' ');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double optionWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : 100.w;

        final platterWidget = SizedBox(
          width: optionWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The Cloche (Silver Dome)
              Container(
                height: 50.h,
                decoration: BoxDecoration(
                  color: AppColors.slate200, // Silver
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(40.r)),
                  border: Border.all(color: AppColors.slate400, width: 2),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, AppColors.slate300],
                  ),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: EdgeInsets.only(top: 4.h),
                    width: 15.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: AppColors.slate400, // Dome handle
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
              ),
              // The Platter Base
              Container(
                height: 60.h,
                decoration: BoxDecoration(
                  color: AppColors.slate100, // Light silver plate
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(16.r)),
                  border: Border.all(color: AppColors.slate400, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (emojiPart.isNotEmpty)
                          Text(emojiPart, style: TextStyle(fontSize: 18.sp)),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              namePart,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        final draggable = Draggable<String>(
          data: text,
          maxSimultaneousDrags: state.answerStatus.isAnswered ? 0 : 1,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: optionWidth,
              child: Transform.scale(
                scale: 1.05,
                child: Opacity(opacity: 0.9, child: platterWidget),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: platterWidget),
          child: platterWidget,
        );

        return GestureDetector(
          onTap: state.answerStatus.isAnswered
              ? null
              : () => _handleAnswer(context, state, state.currentQuest, text),
          child: draggable,
        );
      },
    );
  }
}

const String _checkeredTableclothSvg = '''
<svg width="2000" height="200" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <pattern id="checker" width="40" height="40" patternUnits="userSpaceOnUse">
      <rect width="40" height="40" fill="#E53935" />
      <rect x="0" y="0" width="20" height="20" fill="#FFFFFF" opacity="0.9" />
      <rect x="20" y="20" width="20" height="20" fill="#FFFFFF" opacity="0.9" />
    </pattern>
  </defs>
  <rect width="100%" height="100%" fill="url(#checker)" />
</svg>
''';
