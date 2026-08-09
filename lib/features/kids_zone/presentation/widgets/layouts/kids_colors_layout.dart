import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Art Studio Theme for Colors Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsColorsLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsColorsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'colors',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Artist Easel
            Expanded(
              flex: 5,
              child: Center(child: _buildEasel(context, state, quest)),
            ),

            SizedBox(height: 24.h),
            Text(
              context.tr(
                'games.kids_colors_drag',
                fallback: 'Drag the paint to the canvas! 🎨',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 16.h),

            // The Squeezed Paint Tubes
            Flexible(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(quest.options?.length ?? 0, (index) {
                    final option = quest.options![index];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: _buildPaintTube(
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
            
            // Small AAA Design Card for Fun Facts (Standardized across modules)
            if (quest.funFact != null)
              Padding(
                padding: EdgeInsets.only(top: 16.h, bottom: 24.h, left: 32.w, right: 32.w),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 2.w,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_circle_rounded,
                        color: primaryColor,
                        size: 28.r,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: AutoSizeText(
                          quest.funFact!,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.black.withValues(alpha: 0.8),
                          ),
                          maxLines: 2,
                          minFontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEasel(BuildContext context, KidsLoaded state, dynamic quest) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final text = details.data;
        final isCorrect = (text == quest.correctAnswer);
        di.sl<KidsTTSService>().speak(text);
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Wooden back legs of the easel
            Positioned(
              top: -20.h,
              child: Container(
                width: 140.w,
                height: 250.h,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: const Color(0xFF92400E),
                      width: 12.w,
                    ),
                    right: BorderSide(
                      color: const Color(0xFF92400E),
                      width: 12.w,
                    ),
                  ),
                ),
              ),
            ),
            // The Canvas
            Container(
              width: 280.w,
              height: 200.h,
              decoration: BoxDecoration(
                color: isHovering
                    ? const Color(0xFFFDE047)
                    : Colors.white, // Highlight canvas on hover
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(
                  color: isHovering
                      ? const Color(0xFFEAB308)
                      : const Color(0xFFD4D4D8),
                  width: isHovering ? 4 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isHovering ? 0.3 : 0.1,
                    ),
                    blurRadius: isHovering ? 20 : 10,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (quest.emoji != null)
                      Text(
                        quest.emoji!,
                        style: TextStyle(fontSize: 80.sp),
                      ), // Enlarge emoji, hide question text
                  ],
                ),
              ),
            ),
            // Wooden tray at the bottom of the canvas
            Positioned(
              bottom: 0,
              child: Container(
                width: 300.w,
                height: 20.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFB45309),
                  borderRadius: BorderRadius.circular(4.r),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, offset: Offset(0, 4)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaintTube(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    // Determine color based on text if possible, otherwise fallback to primary
    Color tubeColor = _getColorFromName(text, primaryColor);

    final tubeWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Paint Splatter at the top (simulating squeezed paint)
        Icon(Icons.water_drop_rounded, color: tubeColor, size: 28.r),
        // The Tube
        Container(
          height: 90.h,
          width: 75.w, // Fixed width prevents infinite constraint crash in Draggable feedback
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8.r),
              topRight: Radius.circular(8.r),
              bottomLeft: Radius.circular(20.r),
              bottomRight: Radius.circular(20.r),
            ),
            border: Border.all(color: const Color(0xFFE4E4E7), width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black12, offset: Offset(0, 6.h)),
            ],
          ),
          child: Column(
            children: [
              // Tube label color strip
              Container(height: 30.h, width: double.infinity, color: tubeColor),
              Expanded(
                child: Center(
                  child: AutoSizeText(
                    text,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3F3F46),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    minFontSize: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Tube Cap
        Container(
          height: 12.h,
          width: 30.w,
          decoration: BoxDecoration(
            color: const Color(0xFF52525B), // Grey cap
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4.r)),
          ),
        ),
      ],
    );

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(opacity: 0.9, child: tubeWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: tubeWidget),
      child: tubeWidget,
    );
  }

  Color _getColorFromName(String name, Color fallback) {
    final lower = name.toLowerCase();
    
    // Advanced Shades (must check before base colors)
    if (lower.contains('light blue') || lower.contains('baby blue') || lower.contains('sky blue')) return Colors.lightBlue;
    if (lower.contains('dark blue') || lower.contains('navy')) return const Color(0xFF000080);
    if (lower.contains('light green') || lower.contains('mint') || lower.contains('sage')) return Colors.lightGreen;
    if (lower.contains('dark green') || lower.contains('forest') || lower.contains('olive')) return const Color(0xFF006400);
    if (lower.contains('dark red') || lower.contains('maroon') || lower.contains('burgundy')) return const Color(0xFF800000);
    if (lower.contains('light red') || lower.contains('salmon')) return const Color(0xFFFA8072);
    if (lower.contains('light yellow') || lower.contains('pastel yellow')) return const Color(0xFFFFFACD);
    if (lower.contains('dark purple') || lower.contains('plum') || lower.contains('eggplant')) return const Color(0xFF4B0082);
    if (lower.contains('light purple') || lower.contains('lavender') || lower.contains('lilac')) return const Color(0xFFE6E6FA);
    if (lower.contains('dark brown') || lower.contains('chocolate') || lower.contains('espresso')) return const Color(0xFF3E2723);
    if (lower.contains('light brown') || lower.contains('tan') || lower.contains('khaki') || lower.contains('beige') || lower.contains('cream') || lower.contains('oatmeal')) return const Color(0xFFD2B48C);
    if (lower.contains('dark gray') || lower.contains('dark grey') || lower.contains('charcoal')) return const Color(0xFF424242);
    if (lower.contains('light gray') || lower.contains('light grey') || lower.contains('silver')) return const Color(0xFFBDBDBD);
    if (lower.contains('hot pink') || lower.contains('neon pink') || lower.contains('fuchsia') || lower.contains('magenta')) return Colors.pinkAccent;

    // Mixed & Tertiary Colors
    if (lower.contains('teal')) return Colors.teal;
    if (lower.contains('cyan') || lower.contains('aqua') || lower.contains('turquoise')) return Colors.cyan;
    if (lower.contains('peach') || lower.contains('coral') || lower.contains('apricot')) return const Color(0xFFFFDAB9);
    if (lower.contains('gold')) return const Color(0xFFFFD700);
    if (lower.contains('lime') || lower.contains('chartreuse')) return const Color(0xFF32CD32);
    if (lower.contains('indigo')) return Colors.indigo;

    // Gemstones & Minerals
    if (lower.contains('ruby') || lower.contains('garnet') || lower.contains('scarlet') || lower.contains('brick')) return const Color(0xFFB22222);
    if (lower.contains('emerald') || lower.contains('jade')) return const Color(0xFF50C878);
    if (lower.contains('sapphire')) return const Color(0xFF0F52BA);
    if (lower.contains('amethyst')) return const Color(0xFF9966CC);
    if (lower.contains('topaz') || lower.contains('citrine')) return const Color(0xFFFFC87C);
    if (lower.contains('onyx') || lower.contains('coal')) return Colors.black87;

    // Base Colors
    if (lower.contains('red')) return Colors.red;
    if (lower.contains('blue')) return Colors.blue;
    if (lower.contains('green')) return Colors.green;
    if (lower.contains('yellow')) return Colors.yellow;
    if (lower.contains('orange')) return Colors.orange;
    if (lower.contains('purple')) return Colors.purple;
    if (lower.contains('pink')) return Colors.pink;
    if (lower.contains('black')) return Colors.black;
    if (lower.contains('white') || lower.contains('snow') || lower.contains('pearl')) {
      return const Color(0xFFE4E4E7); // Off-white for visibility on canvas
    }
    if (lower.contains('brown')) return Colors.brown;
    if (lower.contains('gray') || lower.contains('grey')) return Colors.grey;

    return fallback;
  }
}
