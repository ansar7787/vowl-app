import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/features/kids_zone/theme/kids_colors.dart';
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

class _LocalPalette {
  _LocalPalette._();
  static const Color c_92400E = Color(0xFF92400E);
  static const Color c_FDE047 = Color(0xFFFDE047);
  static const Color c_EAB308 = Color(0xFFEAB308);
  static const Color c_D4D4D8 = Color(0xFFD4D4D8);
  static const Color c_9CA3AF = Color(0xFF9CA3AF);
  static const Color c_E4E4E7 = Color(0xFFE4E4E7);
  static const Color c_3F3F46 = Color(0xFF3F3F46);
  static const Color c_52525B = Color(0xFF52525B);
  static const Color c_000080 = Color(0xFF000080);
  static const Color c_006400 = Color(0xFF006400);
  static const Color c_800000 = Color(0xFF800000);
  static const Color c_FA8072 = Color(0xFFFA8072);
  static const Color c_FFFACD = Color(0xFFFFFACD);
  static const Color c_4B0082 = Color(0xFF4B0082);
  static const Color c_E6E6FA = Color(0xFFE6E6FA);
  static const Color c_3E2723 = Color(0xFF3E2723);
  static const Color c_D2B48C = Color(0xFFD2B48C);
  static const Color c_424242 = Color(0xFF424242);
  static const Color c_BDBDBD = Color(0xFFBDBDBD);
  static const Color c_FFDAB9 = Color(0xFFFFDAB9);
  static const Color c_32CD32 = Color(0xFF32CD32);
  static const Color c_B22222 = Color(0xFFB22222);
  static const Color c_50C878 = Color(0xFF50C878);
  static const Color c_0F52BA = Color(0xFF0F52BA);
  static const Color c_9966CC = Color(0xFF9966CC);
  static const Color c_FFC87C = Color(0xFFFFC87C);
}

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
            KidsFittedText(
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
              maxLines: 2,
              textAlign: TextAlign.center,
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
        if (!isCorrect) {
          di.sl<KidsTTSService>().speak(text);
        }
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
                      color: _LocalPalette.c_92400E,
                      width: 12.w,
                    ),
                    right: BorderSide(
                      color: _LocalPalette.c_92400E,
                      width: 12.w,
                    ),
                  ),
                ),
              ),
            ),
            // The Canvas
            InkWell(
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
                width: 280.w,
                height: 200.h,
                decoration: BoxDecoration(
                  color: isHovering
                      ? _LocalPalette.c_FDE047
                      : Colors.white, // Highlight canvas on hover
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(
                    color: isHovering
                        ? _LocalPalette.c_EAB308
                        : _LocalPalette.c_D4D4D8,
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
                        state.answerStatus == AnswerStatus.correct
                            ? Text(
                                quest.emoji!,
                                style: TextStyle(fontSize: 100.sp),
                              )
                            : ColorFiltered(
                                colorFilter: const ColorFilter.mode(
                                  _LocalPalette.c_9CA3AF,
                                  BlendMode.srcIn,
                                ),
                                child: Text(
                                  quest.emoji!,
                                  style: TextStyle(fontSize: 100.sp),
                                ),
                              ), // Enlarge emoji, hide question text
                    ],
                  ),
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
                  color: KidsColors.warmAmber,
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
          width: 75
              .w, // Fixed width prevents infinite constraint crash in Draggable feedback
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8.r),
              topRight: Radius.circular(8.r),
              bottomLeft: Radius.circular(20.r),
              bottomRight: Radius.circular(20.r),
            ),
            border: Border.all(color: _LocalPalette.c_E4E4E7, width: 2),
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
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 65.w,
                      child: Text(
                        text,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: _LocalPalette.c_3F3F46,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                      ),
                    ),
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
            color: _LocalPalette.c_52525B, // Grey cap
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
    if (lower.contains('light blue') ||
        lower.contains('baby blue') ||
        lower.contains('sky blue')) {
      return Colors.lightBlue;
    }
    if (lower.contains('dark blue') || lower.contains('navy')) {
      return _LocalPalette.c_000080;
    }
    if (lower.contains('light green') ||
        lower.contains('mint') ||
        lower.contains('sage')) {
      return Colors.lightGreen;
    }
    if (lower.contains('dark green') ||
        lower.contains('forest') ||
        lower.contains('olive')) {
      return _LocalPalette.c_006400;
    }
    if (lower.contains('dark red') ||
        lower.contains('maroon') ||
        lower.contains('burgundy')) {
      return _LocalPalette.c_800000;
    }
    if (lower.contains('light red') || lower.contains('salmon')) {
      return _LocalPalette.c_FA8072;
    }
    if (lower.contains('light yellow') || lower.contains('pastel yellow')) {
      return _LocalPalette.c_FFFACD;
    }
    if (lower.contains('dark purple') ||
        lower.contains('plum') ||
        lower.contains('eggplant')) {
      return _LocalPalette.c_4B0082;
    }
    if (lower.contains('light purple') ||
        lower.contains('lavender') ||
        lower.contains('lilac')) {
      return _LocalPalette.c_E6E6FA;
    }
    if (lower.contains('dark brown') ||
        lower.contains('chocolate') ||
        lower.contains('espresso')) {
      return _LocalPalette.c_3E2723;
    }
    if (lower.contains('light brown') ||
        lower.contains('tan') ||
        lower.contains('khaki') ||
        lower.contains('beige') ||
        lower.contains('cream') ||
        lower.contains('oatmeal')) {
      return _LocalPalette.c_D2B48C;
    }
    if (lower.contains('dark gray') ||
        lower.contains('dark grey') ||
        lower.contains('charcoal')) {
      return _LocalPalette.c_424242;
    }
    if (lower.contains('light gray') ||
        lower.contains('light grey') ||
        lower.contains('silver')) {
      return _LocalPalette.c_BDBDBD;
    }
    if (lower.contains('hot pink') ||
        lower.contains('neon pink') ||
        lower.contains('fuchsia') ||
        lower.contains('magenta')) {
      return Colors.pinkAccent;
    }

    // Mixed & Tertiary Colors
    if (lower.contains('teal')) {
      return Colors.teal;
    }
    if (lower.contains('cyan') ||
        lower.contains('aqua') ||
        lower.contains('turquoise')) {
      return Colors.cyan;
    }
    if (lower.contains('peach') ||
        lower.contains('coral') ||
        lower.contains('apricot')) {
      return _LocalPalette.c_FFDAB9;
    }
    if (lower.contains('gold')) {
      return IllustrationColors.premiumGold;
    }
    if (lower.contains('lime') || lower.contains('chartreuse')) {
      return _LocalPalette.c_32CD32;
    }
    if (lower.contains('indigo')) {
      return Colors.indigo;
    }

    // Gemstones & Minerals
    if (lower.contains('ruby') ||
        lower.contains('garnet') ||
        lower.contains('scarlet') ||
        lower.contains('brick')) {
      return _LocalPalette.c_B22222;
    }
    if (lower.contains('emerald') || lower.contains('jade')) {
      return _LocalPalette.c_50C878;
    }
    if (lower.contains('sapphire')) {
      return _LocalPalette.c_0F52BA;
    }
    if (lower.contains('amethyst')) {
      return _LocalPalette.c_9966CC;
    }
    if (lower.contains('topaz') || lower.contains('citrine')) {
      return _LocalPalette.c_FFC87C;
    }
    if (lower.contains('onyx') || lower.contains('coal')) {
      return Colors.black87;
    }

    // Base Colors
    if (lower.contains('red')) {
      return Colors.red;
    }
    if (lower.contains('blue')) {
      return Colors.blue;
    }
    if (lower.contains('green')) {
      return Colors.green;
    }
    if (lower.contains('yellow')) {
      return Colors.yellow;
    }
    if (lower.contains('orange')) {
      return Colors.orange;
    }
    if (lower.contains('purple')) {
      return Colors.purple;
    }
    if (lower.contains('pink')) {
      return Colors.pink;
    }
    if (lower.contains('black')) {
      return Colors.black;
    }
    if (lower.contains('white') ||
        lower.contains('snow') ||
        lower.contains('pearl')) {
      return _LocalPalette.c_E4E4E7; // Off-white for visibility on canvas
    }
    if (lower.contains('brown')) {
      return Colors.brown;
    }
    if (lower.contains('gray') || lower.contains('grey')) {
      return Colors.grey;
    }

    return fallback;
  }
}
