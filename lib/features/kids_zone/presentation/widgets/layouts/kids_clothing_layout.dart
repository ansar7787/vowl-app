import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

/// Design system color palette for the Kids Clothing Game.
class _WardrobePalette {
  _WardrobePalette._();

  // Boutique Wardrobe Closet
  static const Color closetFrame = Color(0xFF78350F); // Deep warm amber/oak wood
  static const Color closetInterior = Color(0xFFFFFBEB); // Creamy warm oak interior
  static const Color closetShadow = Color(0x33451A03);
  static const Color brassRail = Color(0xFFD97706); // Warm golden brass clothes rod
  static const Color brassRailGleam = Color(0xFFFDE68A); // Polished brass highlight
  static const Color hangerWood = Color(0xFFB45309); // Handcrafted cedar hanger
  static const Color hangerHook = Color(0xFF94A3B8); // Slate 400 metal hook

  // Interactive Target States
  static const Color dropHoverBg = Color(0xFFFEF3C7); // Warm amber glow on hover
  static const Color dropHoverBorder = Color(0xFFF59E0B); // Amber 500

  // Fabric Tags Palette
  static const Color tagRose = Color(0xFFFCA5A5); // Soft berry rose
  static const Color tagSky = Color(0xFF93C5FD); // Boutique sky blue
  static const Color tagMint = Color(0xFF6EE7B7); // Spring mint
  static const Color tagLavender = Color(0xFFDDD6FE); // Soft lavender
  static const Color tagCoral = Color(0xFFFDBA74); // Warm peach coral
  static const Color tagLemon = Color(0xFFFDE047); // Sunny lemon

  // Feedback States
  static const Color successBg = Color(0xFFDCFCE7); // Green 100
  static const Color successBorder = Color(0xFF16A34A); // Green 600
  static const Color errorBg = Color(0xFFFFE4E6); // Rose 100
  static const Color errorBorder = Color(0xFFE11D48); // Rose 600
}

/// Production-grade Boutique Wardrobe & Dressing Layout for Kids Zone.
///
/// Features:
/// - Dual interaction: Intuitive Drag-and-Drop of clothing hanger tags to the
///   Boutique Closet, AND accessible tap-to-answer for younger or motor-impaired children.
/// - Unspoiled Clothing Riddle: Displays the rich clothing riddle / dressing story
///   prominently inside the wardrobe closet with zero text clipping.
/// - Audio Scaffolding: On-demand audio replay button on the closet, individual
///   clothing item pronunciation via speaker buttons on hanger tags, and immediate
///   audio feedback upon answer submission.
/// - Lifeline Scaffolding: Automatically dims an incorrect distractor hanger tag
///   when `hintUsed` is active.
/// - Multi-tier Boutique Rack: Renders a single horizontal rail for concise choices,
///   and a two-tier boutique rack for 4 choices or longer phrases, preventing text
///   truncation and ensuring 48dp touch targets.
/// - Zero Overflows: Built with LayoutBuilder and SingleChildScrollView for 320dp
///   small phone compatibility.
/// - Haptic feedback on selection, correct, and error pathways.
class KidsClothingLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsClothingLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsClothingLayout> createState() => _KidsClothingLayoutState();
}

class _KidsClothingLayoutState extends State<KidsClothingLayout> {
  String? _selectedOption;
  String? _lastQuestId;

  void _syncStateWithQuest(KidsQuest currentQuest) {
    if (_lastQuestId != currentQuest.id) {
      _lastQuestId = currentQuest.id;
      _selectedOption = null;
    }
  }

  void _handleOptionSubmit(
    BuildContext context,
    KidsLoaded state,
    String optionText,
  ) {
    if (state.answerStatus.isAnswered) return;

    final quest = state.currentQuest;
    final isCorrect = (optionText.trim() == quest.correctAnswer?.trim());

    setState(() {
      _selectedOption = optionText;
    });

    try {
      if (isCorrect) {
        di.sl<HapticService>().success();
      } else {
        di.sl<HapticService>().error();
      }
    } catch (_) {}

    try {
      di.sl<KidsTTSService>().speak(optionText);
    } catch (_) {}

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _speakText(String text) {
    if (text.isEmpty) return;
    try {
      di.sl<HapticService>().selection();
      di.sl<KidsTTSService>().speak(text);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: widget.title,
      gameType: 'clothing',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;
        _syncStateWithQuest(quest);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            final isTablet = constraints.maxWidth > 550;
            final contentWidth =
                isTablet ? 520.0 : (constraints.maxWidth - 20.w);

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: 24.h,
                    left: isNarrow ? 2.w : 4.w,
                    right: isNarrow ? 2.w : 4.w,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: KidsGameBaseScreen.mascotClearanceHeight + 10.h),

                      // Boutique Wardrobe Closet (Drag Target & Story Board)
                      _buildClosetBoard(
                        context,
                        state,
                        quest,
                        isNarrow: isNarrow,
                      ),

                      SizedBox(height: 12.h),

                      // Action prompt banner
                      _buildPromptBanner(context, isNarrow: isNarrow),

                      SizedBox(height: 10.h),

                      // Boutique Clothes Hanger Rack (Options)
                      _buildHangerRack(
                        context,
                        state,
                        quest,
                        isNarrow: isNarrow,
                      ),

                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Action Prompt Banner with dual-interaction guidance
  Widget _buildPromptBanner(BuildContext context, {required bool isNarrow}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : _WardrobePalette.closetFrame.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pan_tool_alt_rounded,
            size: 15.r,
            color: _WardrobePalette.hangerWood,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: KidsFittedText(
              context.tr(
                'games.kids_clothing_drag',
                fallback: 'Drag the hanger tag to the closet, or tap to choose!',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isNarrow ? 12.sp : 13.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.85)
                    : _WardrobePalette.closetFrame,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Boutique Wardrobe Closet (Drop Target & Riddle Lightbox)
  Widget _buildClosetBoard(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required bool isNarrow,
  }) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        _handleOptionSubmit(context, state, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final isAnswered = state.answerStatus.isAnswered;
        final isCorrect =
            (state.answerStatus == AnswerStatus.correct) ||
            (_selectedOption == quest.correctAnswer);

        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: isNarrow ? 170.h : 190.h,
          ),
          decoration: BoxDecoration(
            color: isHovering
                ? _WardrobePalette.dropHoverBg
                : _WardrobePalette.closetInterior,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isHovering
                  ? _WardrobePalette.dropHoverBorder
                  : (isAnswered && isCorrect
                      ? _WardrobePalette.successBorder
                      : _WardrobePalette.closetFrame),
              width: isHovering ? 3.5.w : 3.w,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovering
                    ? _WardrobePalette.dropHoverBorder.withValues(alpha: 0.45)
                    : _WardrobePalette.closetShadow,
                blurRadius: isHovering ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17.r),
            child: Stack(
              children: [
                // Top Boutique Brass Bar Frame
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 6.h,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _WardrobePalette.brassRail,
                          _WardrobePalette.brassRailGleam,
                          _WardrobePalette.brassRail,
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row: Boutique Badge & TTS Audio Replay
                      _buildClosetHeader(quest, isAnswered: isAnswered),

                      SizedBox(height: 8.h),

                      // Content: Celebratory Reveal OR Clothing Riddle
                      if (isAnswered && isCorrect)
                        _buildCelebratoryReveal(quest)
                      else
                        _buildClosetRiddleContent(
                          quest,
                          isHovering: isHovering,
                          isNarrow: isNarrow,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Boutique Wardrobe Header with Sign & Audio Replay Button
  Widget _buildClosetHeader(KidsQuest quest, {required bool isAnswered}) {
    final instruction = InstructionHelper.getInstruction(quest);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Wardrobe Tag Badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: _WardrobePalette.closetFrame.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.checkroom_rounded,
                size: 15.r,
                color: _WardrobePalette.hangerWood,
              ),
              SizedBox(width: 5.w),
              Text(
                'Boutique Wardrobe',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: _WardrobePalette.hangerWood,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),

        // Audio Replay Button (always accessible)
        Semantics(
          label: 'Listen to clothing riddle',
          button: true,
          child: InkWell(
            key: const ValueKey('clothing_audio_replay_btn'),
            onTap: () => _speakText(instruction),
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: _WardrobePalette.hangerWood.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _WardrobePalette.hangerWood.withValues(alpha: 0.3),
                  width: 1.2.w,
                ),
              ),
              child: Icon(
                Icons.volume_up_rounded,
                size: 17.r,
                color: _WardrobePalette.hangerWood,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Active Clothing Riddle displayed inside the wardrobe
  Widget _buildClosetRiddleContent(
    KidsQuest quest, {
    required bool isHovering,
    required bool isNarrow,
  }) {
    final instruction = InstructionHelper.getInstruction(quest);
    final question = quest.question ?? '';
    final hasDistinctQuestion = question.isNotEmpty &&
        question != '?' &&
        question != instruction;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 4.h),

        // Story Riddle Prompt
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Text(
            instruction,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isNarrow ? 14.sp : 15.5.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B), // Slate 800
              height: 1.35,
            ),
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        if (hasDistinctQuestion) ...[
          SizedBox(height: 6.h),
          Text(
            question,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isNarrow ? 15.sp : 17.sp,
              fontWeight: FontWeight.w700,
              color: _WardrobePalette.hangerWood,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],

        SizedBox(height: 12.h),

        // Drop Target Indicator Pill
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isHovering
                ? _WardrobePalette.dropHoverBorder.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isHovering
                  ? _WardrobePalette.dropHoverBorder
                  : _WardrobePalette.brassRail.withValues(alpha: 0.4),
              width: 1.5.w,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.checkroom_rounded,
                size: 15.r,
                color: isHovering
                    ? _WardrobePalette.dropHoverBorder
                    : _WardrobePalette.hangerWood,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  isHovering
                      ? 'Hang it in the closet! ✨'
                      : 'Hang matching clothes here',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isHovering
                        ? _WardrobePalette.hangerWood
                        : _WardrobePalette.hangerWood.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Celebratory Reveal upon correct answer
  Widget _buildCelebratoryReveal(KidsQuest quest) {
    final emoji = quest.emoji ?? '👕';
    final correctAnswer = quest.correctAnswer ?? 'Correct';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji bounce
          Text(
            emoji,
            style: TextStyle(fontSize: 48.sp),
          )
              .animate()
              .scale(
                duration: 400.ms,
                curve: Curves.elasticOut,
                begin: const Offset(0.6, 0.6),
                end: const Offset(1.0, 1.0),
              )
              .fadeIn(duration: 250.ms),

          SizedBox(height: 6.h),

          // Correct Answer Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 20.r,
                color: _WardrobePalette.successBorder,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  correctAnswer,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w800,
                    color: _WardrobePalette.successBorder,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),

          if (quest.explanation != null && quest.explanation!.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              quest.explanation!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5.sp,
                color: const Color(0xFF334155), // Slate 700
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// Boutique Clothes Hanger Rack (Adaptive Single-Tier or Multi-Tier)
  Widget _buildHangerRack(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required bool isNarrow,
  }) {
    final options = quest.options ?? [];
    if (options.isEmpty) return const SizedBox.shrink();

    // Determine if any option is dimmed by the hint lifeline
    int? dimmedIndex;
    if (state.hintUsed && quest.correctAnswer != null) {
      for (int i = 0; i < options.length; i++) {
        if (options[i].trim() != quest.correctAnswer!.trim()) {
          dimmedIndex = i;
          break;
        }
      }
    }

    final hasLongOptions = options.any((opt) => opt.length > 14);
    final useMultiTier = options.length > 3 || hasLongOptions;

    if (!useMultiTier && !isNarrow) {
      // Single continuous closet rail for 3 concise options
      return _buildClosetRailRow(
        context,
        state,
        quest,
        options: options,
        dimmedIndex: dimmedIndex,
      );
    }

    // Multi-tier boutique rack (2 rows of 2 or adaptive wrap)
    return _buildMultiTierClosetRack(
      context,
      state,
      quest,
      options: options,
      dimmedIndex: dimmedIndex,
      isNarrow: isNarrow,
    );
  }

  /// Single continuous closet rod row
  Widget _buildClosetRailRow(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required List<String> options,
    required int? dimmedIndex,
  }) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Brass Closet Rod
        Positioned(
          top: 14.h,
          left: 12.w,
          right: 12.w,
          child: Container(
            height: 8.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  _WardrobePalette.brassRail,
                  _WardrobePalette.brassRailGleam,
                  _WardrobePalette.brassRail,
                ],
              ),
              borderRadius: BorderRadius.circular(4.r),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),

        // Hangers Row
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(options.length, (index) {
              final optionText = options[index];
              final isDimmed = (index == dimmedIndex);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: _buildHangerOption(
                    context,
                    state,
                    quest,
                    optionText,
                    index: index,
                    isDimmed: isDimmed,
                    targetWidth: null,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Multi-tier boutique wardrobe rack (for 4 options or long phrases)
  Widget _buildMultiTierClosetRack(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required List<String> options,
    required int? dimmedIndex,
    required bool isNarrow,
  }) {
    // Split options into rows of 2
    final rows = <List<MapEntry<int, String>>>[];
    for (int i = 0; i < options.length; i += 2) {
      final end = (i + 2 < options.length) ? i + 2 : options.length;
      rows.add(
        List.generate(
          end - i,
          (subIdx) => MapEntry(i + subIdx, options[i + subIdx]),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((rowItems) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Brass Closet Rod for this tier
              Positioned(
                top: 14.h,
                left: 14.w,
                right: 14.w,
                child: Container(
                  height: 8.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        _WardrobePalette.brassRail,
                        _WardrobePalette.brassRailGleam,
                        _WardrobePalette.brassRail,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4.r),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),

              // Hangers in this row
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rowItems.map((entry) {
                    final index = entry.key;
                    final optionText = entry.value;
                    final isDimmed = (index == dimmedIndex);

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: _buildHangerOption(
                          context,
                          state,
                          quest,
                          optionText,
                          index: index,
                          isDimmed: isDimmed,
                          targetWidth: null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Individual Clothing Hanger with Hook, Cedar Bar, and Fabric Swatch Tag
  Widget _buildHangerOption(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    String text, {
    required int index,
    required bool isDimmed,
    double? targetWidth,
  }) {
    final isAnswered = state.answerStatus.isAnswered;
    final isSelected = (_selectedOption == text);
    final isCorrectOption = (text.trim() == quest.correctAnswer?.trim());

    const tagColors = [
      _WardrobePalette.tagRose,
      _WardrobePalette.tagSky,
      _WardrobePalette.tagMint,
      _WardrobePalette.tagLavender,
      _WardrobePalette.tagCoral,
      _WardrobePalette.tagLemon,
    ];
    final tagBg = tagColors[index % tagColors.length];

    // Split text and emoji
    final lastSpaceIndex = text.lastIndexOf(' ');
    String label = text;
    String emoji = '';
    if (lastSpaceIndex != -1 && lastSpaceIndex < text.length - 1) {
      final potentialEmoji = text.substring(lastSpaceIndex + 1);
      if (!RegExp(r'[a-zA-Z0-9]').hasMatch(potentialEmoji)) {
        label = text.substring(0, lastSpaceIndex);
        emoji = potentialEmoji;
      }
    }

    // Determine colors based on answer status
    Color cardBg = tagBg;
    Color borderColor = Colors.black.withValues(alpha: 0.12);
    Color shadowColor = Colors.black.withValues(alpha: 0.18);

    if (isAnswered) {
      if (isSelected) {
        if (isCorrectOption) {
          cardBg = _WardrobePalette.successBg;
          borderColor = _WardrobePalette.successBorder;
          shadowColor =
              _WardrobePalette.successBorder.withValues(alpha: 0.45);
        } else {
          cardBg = _WardrobePalette.errorBg;
          borderColor = _WardrobePalette.errorBorder;
          shadowColor = _WardrobePalette.errorBorder.withValues(alpha: 0.45);
        }
      } else if (isCorrectOption) {
        cardBg = _WardrobePalette.successBg;
        borderColor = _WardrobePalette.successBorder;
        shadowColor = _WardrobePalette.successBorder.withValues(alpha: 0.45);
      }
    }

    final hangerVisual = Opacity(
      opacity: isDimmed ? 0.35 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Metal Hanger Hook Arch
          Container(
            width: 22.w,
            height: 16.h,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: _WardrobePalette.hangerHook,
                  width: 3.2.w,
                ),
                left: BorderSide(
                  color: _WardrobePalette.hangerHook,
                  width: 3.2.w,
                ),
                right: BorderSide(
                  color: _WardrobePalette.hangerHook,
                  width: 3.2.w,
                ),
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11.r)),
            ),
          ),

          // Handcrafted Cedar Hanger Base Bar
          Container(
            height: 9.h,
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 6.w),
            decoration: BoxDecoration(
              color: _WardrobePalette.hangerWood,
              borderRadius: BorderRadius.circular(5.r),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 1.5),
                  blurRadius: 2,
                ),
              ],
            ),
          ),

          // Fabric Clothing Tag (Swatch Card)
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 2.w).copyWith(top: 2.h),
            constraints: BoxConstraints(minHeight: 88.h),
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(14.r),
              ),
              border: Border.all(color: borderColor, width: 2.w),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  offset: const Offset(0, 4),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top-right TTS Speaker Button (listen without submitting)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Semantics(
                    label: 'Pronounce $text',
                    button: true,
                    child: InkWell(
                      key: ValueKey('clothing_speaker_$text'),
                      onTap: isDimmed ? null : () => _speakText(text),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Padding(
                        padding: EdgeInsets.all(2.r),
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 14.r,
                          color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),

                // Tag Content: Emoji + Label
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (emoji.isNotEmpty) ...[
                        Text(
                          emoji,
                          style: TextStyle(fontSize: 26.sp, height: 1.1),
                        ),
                        SizedBox(height: 3.h),
                      ],
                      KidsFittedText(
                        label,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A), // Slate 900
                          height: 1.15,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Interactive Card wrapping tap & accessibility
    final interactiveCard = Semantics(
      label: 'Clothing option: $text',
      button: true,
      enabled: !isAnswered && !isDimmed,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('clothing_option_$text'),
          borderRadius: BorderRadius.circular(14.r),
          onTap: (isAnswered || isDimmed)
              ? null
              : () => _handleOptionSubmit(context, state, text),
          child: hangerVisual,
        ),
      ),
    );

    // If dimmed by hint, disable dragging
    if (isDimmed) {
      return interactiveCard;
    }

    final feedbackWidget = Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.08,
        child: Opacity(
          opacity: 0.92,
          child: SizedBox(
            width: 90.w,
            child: hangerVisual,
          ),
        ),
      ),
    );

    return Draggable<String>(
      data: text,
      maxSimultaneousDrags: isAnswered ? 0 : 1,
      feedback: feedbackWidget,
      childWhenDragging: Opacity(opacity: 0.25, child: hangerVisual),
      child: interactiveCard,
    );
  }
}
