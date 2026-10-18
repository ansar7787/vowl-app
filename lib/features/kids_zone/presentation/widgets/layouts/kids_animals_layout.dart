import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

/// Design system color palette for the Safari Animals Game.
class _SafariPalette {
  _SafariPalette._();

  // Lush Jungle Canopy
  static const Color jungleDark = Color(0xFF14532D); // Deep forest green
  static const Color jungleMid = Color(0xFF166534); // Jungle green
  static const Color jungleLight = Color(0xFF15803D); // Emerald leaf green

  // Safari Binoculars & Leather Frame
  static const Color leatherDark = Color(0xFF78350F); // Deep saddle leather
  static const Color leatherMedium = Color(0xFF92400E); // Rich amber leather
  static const Color brassGold = Color(0xFFF59E0B); // Polished brass trim
  static const Color brassDark = Color(0xFFD97706); // Dark brass joint

  // Optical Lens Glass
  static const Color lensGlassLight = Color(0xFFE0F2FE); // Soft sky glass tint
  static const Color lensGlassMid = Color(0xFFBAE6FD); // Sky blue glass

  // Wooden Safari Signposts (Options)
  static const Color woodLight = Color(0xFFFDE68A); // Pale cedar
  static const Color woodDark = Color(0xFFD97706); // Dark teak
  static const Color woodBorder = Color(0xFF92400E); // Timber outline
  static const Color woodPost = Color(0xFF78350F); // Wooden stake

  // Interactive Target States
  static const Color hoverGlow = Color(0xFFFBBF24); // Amber 400 target glow

  // Feedback States
  static const Color successBg = Color(0xFFDCFCE7); // Green 100
  static const Color successBorder = Color(0xFF16A34A); // Green 600
  static const Color successText = Color(0xFF15803D); // Green 700
  static const Color errorBg = Color(0xFFFFE4E6); // Rose 100
  static const Color errorBorder = Color(0xFFE11D48); // Rose 600
}

/// Production-grade Safari Animals Discovery Layout for Kids Zone.
///
/// Features:
/// - Dual interaction: Intuitive Drag-and-Drop of wooden animal signposts to the
///   Safari Binoculars, AND accessible tap-to-answer for younger or motor-impaired children.
/// - Unspoiled Safari Riddle: Displays clear, unoccluded animal riddles without spoiling
///   the animal name before the child makes their choice.
/// - Dynamic Optical Binoculars: Beautiful brass & leather binoculars with realistic lens
///   shading, ambient jungle leaf accents, and an interactive drop target with hover glow
///   that transforms into a celebratory animal reveal upon correct completion.
/// - Audio scaffolding: Pronounces target animal sounds and instructions on demand
///   and upon submission, with dedicated speaker buttons on the binoculars and signposts.
/// - Adaptive signpost layout: Renders tactile 3D wooden safari signposts with high-contrast
///   emojis and labels, with zero unmanaged ticker loops (eliminating battery drain).
/// - Lifeline integration: Automatically dims a distractor signpost when `hintUsed` is active.
/// - Visual hierarchy & 2026 polish: Rich jungle textures, tactile cartoon shadows, vibrant
///   feedback states, and full screen-reader Semantics support.
/// - Responsive & scroll-safe: LayoutBuilder + SingleChildScrollView guarantees zero
///   RenderFlex overflows across 320dp to tablet dimensions.
class KidsAnimalsLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsAnimalsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsAnimalsLayout> createState() => _KidsAnimalsLayoutState();
}

class _KidsAnimalsLayoutState extends State<KidsAnimalsLayout> {
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

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Animal option selected: "$optionText" (Correct: $isCorrect)',
        tag: 'KidsAnimals',
      );
    }

    try {
      if (isCorrect) {
        di.sl<HapticService>().success();
      } else {
        di.sl<HapticService>().error();
      }
    } catch (_) {}

    try {
      if (isCorrect) {
        // Play animal sound or animal name on correct
        final sound = quest.animalSound ?? quest.question ?? optionText;
        di.sl<KidsTTSService>().speak(sound, force: true);
      } else {
        // Speak chosen option on incorrect
        di.sl<KidsTTSService>().speak(optionText, force: true);
      }
    } catch (_) {}

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _playOptionAudio(String text, KidsQuest quest) {
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Playing audio for option: "$text"',
        tag: 'KidsAnimals',
      );
    }
    try {
      final textToSpeak = (text == quest.correctAnswer && quest.animalSound != null)
          ? '${quest.question ?? ''}. ${quest.animalSound}'
          : text;
      di.sl<KidsTTSService>().speak(textToSpeak, force: true);
      di.sl<HapticService>().selection();
    } catch (e) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().warning(
          'Failed to pronounce animal option "$text": $e',
          tag: 'KidsAnimals',
        );
      }
    }
  }

  void _replayQuestionAudio(KidsQuest quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    final question = quest.question ?? '';
    final textToSpeak = instruction.isNotEmpty
        ? (question.isNotEmpty && question != '?'
            ? instruction
            : instruction)
        : question;

    if (textToSpeak.isNotEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'Replaying instruction audio for quest "${quest.id}"',
          tag: 'KidsAnimals',
        );
      }
      try {
        di.sl<KidsTTSService>().speak(textToSpeak, force: true);
        di.sl<HapticService>().selection();
      } catch (e) {
        if (di.sl.isRegistered<AppLogger>()) {
          di.sl<AppLogger>().warning(
            'Failed to replay audio for quest "${quest.id}": $e',
            tag: 'KidsAnimals',
          );
        }
      }
    }
  }
  @override
  void dispose() {
    try {
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().stop();
      }
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: widget.title,
      gameType: 'animals',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;
        _syncStateWithQuest(quest);

        return Stack(
          children: [
            // Lush jungle decorative foliage in corners
            Positioned(
              top: 40.h,
              left: -20.w,
              child: _SafariLeaf(
                color: _SafariPalette.jungleMid,
                size: 72,
                rotation: 0.5,
              ),
            ),
            Positioned(
              top: 90.h,
              right: -15.w,
              child: _SafariLeaf(
                color: _SafariPalette.jungleDark,
                size: 88,
                rotation: -0.7,
              ),
            ),
            Positioned(
              bottom: 110.h,
              left: -24.w,
              child: _SafariLeaf(
                color: _SafariPalette.jungleLight,
                size: 96,
                rotation: 0.3,
              ),
            ),

            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final isTablet = constraints.maxWidth > 550;
                final contentWidth = isTablet
                    ? 520.0
                    : (constraints.maxWidth - 24.w);

                return Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: 24.h,
                        left: 4.w,
                        right: 4.w,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: KidsGameBaseScreen.mascotClearanceHeight + 12.h,
                          ),

                          // Safari Binoculars Target Zone
                          _buildBinocularsTarget(
                            context,
                            state,
                            quest,
                            isNarrow: isNarrow,
                          ),

                          SizedBox(height: 14.h),

                          // Interaction Instruction Header
                          _buildInteractionPrompt(context, state),

                          SizedBox(height: 12.h),

                          // Wooden Animal Signpost Options
                          _buildOptionsSection(
                            context,
                            state,
                            quest,
                            isNarrow: isNarrow,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Interactive Safari Binoculars (Target Zone)
  Widget _buildBinocularsTarget(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required bool isNarrow,
  }) {
    final isAnswered = state.answerStatus.isAnswered;
    final isCorrect = state.answerStatus == AnswerStatus.correct;
    final instruction = InstructionHelper.getInstruction(quest);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => !isAnswered,
      onAcceptWithDetails: (details) {
        _handleOptionSubmit(context, state, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Semantics(
          label: isCorrect
              ? 'Correct animal: ${quest.question ?? quest.correctAnswer}'
              : 'Safari binoculars. Riddle: $instruction. Tap an animal below or drag it here.',
          button: true,
          child: Container(
            decoration: BoxDecoration(
              color: _SafariPalette.leatherMedium,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isHovering
                    ? _SafariPalette.hoverGlow
                    : (isCorrect
                        ? _SafariPalette.successBorder
                        : _SafariPalette.leatherDark),
                width: isHovering ? 4.5.w : 3.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHovering
                      ? _SafariPalette.hoverGlow.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.25),
                  blurRadius: isHovering ? 18 : 12,
                  offset: const Offset(0, 6),
                  spreadRadius: isHovering ? 2 : 0,
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header with Safari Brass Badge & Audio Replay Button
                _buildBinocularsHeader(quest, isHovering: isHovering),

                // Main Optical Viewing Area
                Container(
                  margin: EdgeInsets.all(8.r),
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 12.w : 16.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _SafariPalette.lensGlassLight,
                        _SafariPalette.lensGlassMid,
                      ],
                    ),
                    border: Border.all(
                      color: _SafariPalette.brassGold.withValues(alpha: 0.6),
                      width: 1.5.w,
                    ),
                  ),
                  child: isCorrect
                      ? _buildCelebratoryReveal(quest)
                      : _buildBinocularsContent(
                          quest,
                          isHovering,
                          isNarrow: isNarrow,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Decorative Safari Binoculars Header with Brass Accents & Audio Button
  Widget _buildBinocularsHeader(KidsQuest quest, {required bool isHovering}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: _SafariPalette.leatherDark,
        border: Border(
          bottom: BorderSide(
            color: _SafariPalette.brassDark,
            width: 1.5.w,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 16.r,
                color: _SafariPalette.brassGold,
              ),
              SizedBox(width: 6.w),
              Text(
                'SAFARI BINOCULARS',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: _SafariPalette.brassGold,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          // Audio Replay Button
          ScaleButton(
            key: const ValueKey('animals_audio_replay_btn'),
            onTap: () => _replayQuestionAudio(quest),
            child: Container(
              padding: EdgeInsets.all(5.r),
              decoration: BoxDecoration(
                color: _SafariPalette.leatherMedium,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _SafariPalette.brassGold.withValues(alpha: 0.6),
                  width: 1.2.w,
                ),
              ),
              child: Icon(
                Icons.volume_up_rounded,
                size: 16.r,
                color: _SafariPalette.brassGold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Unspoiled Safari Riddle inside the Binoculars
  Widget _buildBinocularsContent(
    KidsQuest quest,
    bool isHovering, {
    required bool isNarrow,
  }) {
    final instruction = InstructionHelper.getInstruction(quest);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Clue Label Badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: _SafariPalette.jungleDark.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pets_rounded,
                size: 14.r,
                color: _SafariPalette.jungleDark,
              ),
              SizedBox(width: 5.w),
              Text(
                'SAFARI CLUE',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: _SafariPalette.jungleDark,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 10.h),

        // Riddle Story Text (Readable, responsive, unspoilered)
        Text(
          instruction,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isNarrow ? 15.sp : 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 12.h),

        // Drop Target Indicator
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isHovering
                ? _SafariPalette.hoverGlow.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isHovering
                  ? _SafariPalette.hoverGlow
                  : _SafariPalette.brassGold.withValues(alpha: 0.5),
              width: 1.5.w,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pan_tool_alt_rounded,
                size: 15.r,
                color: isHovering
                    ? _SafariPalette.leatherDark
                    : _SafariPalette.jungleDark,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  isHovering ? 'Drop animal here!' : 'Spot the animal here',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: isHovering
                        ? _SafariPalette.leatherDark
                        : _SafariPalette.jungleDark,
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

  /// Celebratory Reveal upon correct animal spotting
  Widget _buildCelebratoryReveal(KidsQuest quest) {
    final emoji = quest.correctAnswer ?? '🐾';
    final animalName = quest.question ?? 'Animal';
    final animalSound = quest.animalSound;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _SafariPalette.successBorder,
          width: 2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: _SafariPalette.successBorder.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Spotted Animal Emoji with celebratory pop
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

          // Animal Name
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 20.r,
                color: _SafariPalette.successText,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  animalName,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: _SafariPalette.successText,
                    letterSpacing: 0.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),

          // Animal Sound badge if available
          if (animalSound != null && animalSound.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _SafariPalette.successBg,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: _SafariPalette.successBorder.withValues(alpha: 0.5),
                  width: 1.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_up_rounded,
                    size: 14.r,
                    color: _SafariPalette.successText,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    'Sound: "$animalSound"',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: _SafariPalette.successText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Interaction instruction banner between binoculars and choices
  Widget _buildInteractionPrompt(BuildContext context, KidsLoaded state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _SafariPalette.brassGold.withValues(alpha: 0.5),
          width: 1.2.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 15.r,
            color: _SafariPalette.leatherDark,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: KidsFittedText(
              context.tr(
                'games.kids_animals_drag',
                fallback: 'Drag the animal to the binoculars or tap to choose!',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _SafariPalette.leatherDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Wooden Animal Signpost Options Section
  Widget _buildOptionsSection(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required bool isNarrow,
  }) {
    final options = quest.options ?? [];
    if (options.isEmpty) return const SizedBox.shrink();

    // Identify distractor signpost to dim if hint is active
    String? hintDimOption;
    if (state.hintUsed && !state.answerStatus.isAnswered) {
      hintDimOption = options.firstWhere(
        (opt) => opt != quest.correctAnswer,
        orElse: () => '',
      );
      if (hintDimOption.isEmpty) hintDimOption = null;
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: isNarrow ? 12.w : 16.w,
      runSpacing: isNarrow ? 12.h : 16.h,
      children: options.map((option) {
        final isDimmedByHint = (option == hintDimOption);
        return _buildWoodenSignpost(
          context,
          state,
          quest,
          option,
          isDimmedByHint: isDimmedByHint,
          isNarrow: isNarrow,
        );
      }).toList(),
    );
  }

  /// Tactile Wooden Safari Signpost Card
  Widget _buildWoodenSignpost(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    String text, {
    required bool isDimmedByHint,
    required bool isNarrow,
  }) {
    final isAnswered = state.answerStatus.isAnswered;
    final isSelected = (_selectedOption == text);
    final isCorrectOption = (text == quest.correctAnswer);

    Color boardBgStart = _SafariPalette.woodLight;
    Color boardBgEnd = _SafariPalette.woodDark;
    Color borderColor = _SafariPalette.woodBorder;
    Color shadowColor = _SafariPalette.leatherDark;

    if (isAnswered) {
      if (isSelected) {
        if (isCorrectOption) {
          boardBgStart = _SafariPalette.successBg;
          boardBgEnd = _SafariPalette.successBg;
          borderColor = _SafariPalette.successBorder;
          shadowColor = _SafariPalette.successBorder;
        } else {
          boardBgStart = _SafariPalette.errorBg;
          boardBgEnd = _SafariPalette.errorBg;
          borderColor = _SafariPalette.errorBorder;
          shadowColor = _SafariPalette.errorBorder;
        }
      } else if (isCorrectOption) {
        boardBgStart = _SafariPalette.successBg;
        boardBgEnd = _SafariPalette.successBg;
        borderColor = _SafariPalette.successBorder;
        shadowColor = _SafariPalette.successBorder;
      }
    }

    final double boardWidth = isNarrow ? 84.w : 96.w;
    final double boardHeight = isNarrow ? 66.h : 74.h;

    Widget signpostVisual = Opacity(
      opacity: isDimmedByHint ? 0.35 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The Wooden Plaque Board
          Container(
            width: boardWidth,
            height: boardHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [boardBgStart, boardBgEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: borderColor, width: 2.2.w),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.45),
                  offset: Offset(0, 5.h),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animal Emoji
                Center(
                  child: Text(
                    text,
                    style: TextStyle(fontSize: isNarrow ? 32.sp : 38.sp),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Speaker Button for pronunciation
                Positioned(
                  top: 3.r,
                  right: 3.r,
                  child: Semantics(
                    label: 'Hear $text pronounced',
                    button: true,
                    child: ScaleButton(
                      key: ValueKey('speaker_animal_$text'),
                      onTap: () => _playOptionAudio(text, quest),
                      child: Padding(
                        padding: EdgeInsets.all(4.r),
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 14.r,
                          color: _SafariPalette.leatherDark.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // The Wooden Stake Post holding up the signpost
          Container(
            height: 28.h,
            width: 14.w,
            decoration: BoxDecoration(
              color: _SafariPalette.woodPost,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(4.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(1, 2),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final feedbackWidget = Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.12,
        child: Opacity(
          opacity: 0.95,
          child: signpostVisual,
        ),
      ),
    );

    final interactiveCard = ScaleButton(
      onTap: isAnswered || isDimmedByHint
          ? null
          : () => _handleOptionSubmit(context, state, text),
      child: signpostVisual,
    );

    return Semantics(
      label: 'Animal $text. Tap to choose, or drag to the binoculars.',
      button: true,
      enabled: !isAnswered && !isDimmedByHint,
      child: isAnswered || isDimmedByHint
          ? signpostVisual
          : Draggable<String>(
              data: text,
              maxSimultaneousDrags: isAnswered ? 0 : 1,
              feedback: feedbackWidget,
              childWhenDragging: Opacity(opacity: 0.25, child: signpostVisual),
              child: interactiveCard,
            ),
    );
  }
}

/// Decorative Jungle Leaf Widget
class _SafariLeaf extends StatelessWidget {
  final Color color;
  final double size;
  final double rotation;

  const _SafariLeaf({
    required this.color,
    required this.size,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size.r,
        height: size.r,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size.r),
            bottomRight: Radius.circular(size.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(3, 3),
            ),
          ],
        ),
      ),
    );
  }
}
