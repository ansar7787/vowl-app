import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';

/// Farmer's Market Theme for Fruits Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsFruitsLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsFruitsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'fruits',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Fruit Stand Awning
            Expanded(flex: 5, child: Center(child: _buildAwningFrame(quest))),
            // Wicker Baskets for Options
            Flexible(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(quest.options?.length ?? 0, (index) {
                    final option = quest.options![index];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: _buildBasketOption(
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildAwningFrame(dynamic quest) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main wooden board
        Container(
          width: 280.w,
          height: 200.h,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7), // Light wood
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: const Color(0xFF92400E),
              width: 6.r,
            ), // Dark wood frame
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (quest.emoji != null)
                  Text(quest.emoji!, style: TextStyle(fontSize: 48.sp)),
                Text(
                  quest.question ?? "?",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 48.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF78350F),
                  ),
                ),
                if (quest.funFact != null) ...[
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      quest.funFact!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF92400E), // Medium wood color
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Red and White striped awning on top
        Positioned(
          top: -15.h,
          child: Container(
            width: 280.w,
            height: 40.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: Row(
                children: List.generate(
                  8,
                  (index) => Expanded(
                    child: Container(
                      color: index % 2 == 0 ? Colors.red[600] : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasketOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    final basketColor = const Color(0xFFD97706); // Wicker yellow/brown

    return ScaleButton(
      onTap: () {
        di.sl<KidsTTSService>().speak(text);
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // The label sticking out
          Positioned(
            top: -20.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(color: const Color(0xFF92400E), width: 1),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF451A03),
                ),
                maxLines: 1,
              ),
            ),
          ),
          // The basket
          Container(
            height: 80.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: basketColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.r),
                bottomRight: Radius.circular(20.r),
              ),
              border: Border.all(color: const Color(0xFF78350F), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: CustomPaint(painter: _WickerPainter()),
          ),
        ],
      ),
    );
  }
}

class _WickerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (double y = 10; y < size.height; y += 15) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 10; x < size.width; x += 15) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
