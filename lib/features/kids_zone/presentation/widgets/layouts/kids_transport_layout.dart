import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
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

/// Design system color palette for the Transport & City Transit Game.
class _TransportPalette {
  _TransportPalette._();

  // Highway & Asphalt Road Theme
  static const Color primaryAsphalt = Color(0xFF1E293B); // Slate 800
  static const Color roadSurface = Color(0xFF334155); // Slate 700
  static const Color roadStripe = Color(0xFFFACC15); // Yellow 400
  static const Color crosswalkWhite = Color(0xFFF8FAFC); // Slate 50
  static const Color gantryTruss = Color(0xFF64748B); // Slate 500
  static const Color gantryJoint = Color(0xFF475569); // Slate 600

  // Interstate Highway Overhead Sign (Green Signage)
  static const Color signGreen = Color(0xFF047857); // Emerald 700
  static const Color signGreenDark = Color(0xFF064E3B); // Emerald 900
  static const Color signGreenLight = Color(0xFF059669); // Emerald 600
  static const Color signBorder = Colors.white;
  static const Color signHoverGlow = Color(0xFFFDE047); // Yellow 300

  // Route Shield Badge
  static const Color routeShieldBlue = Color(0xFF1D4ED8); // Blue 700
  static const Color routeShieldRed = Color(0xFFDC2626); // Red 600

  // Transit Vehicle Cards
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0); // Slate 200
  static const Color cardShadow = Color(0xFF0F172A); // Slate 900

  // Feedback States
  static const Color successBg = Color(0xFFDCFCE7); // Green 100
  static const Color successBorder = Color(0xFF16A34A); // Green 600
  static const Color successText = Color(0xFF15803D); // Green 700
  static const Color errorBg = Color(0xFFFFE4E6); // Rose 100
  static const Color errorBorder = Color(0xFFE11D48); // Rose 600
  static const Color errorText = Color(0xFFBE123C); // Rose 700
}

/// Metadata and English vocabulary mappings for Transport items.
class TransportVocabularyHelper {
  TransportVocabularyHelper._();

  static const Map<String, String> _vocab = {
    // Road & Land Vehicles
    '🚗': 'Car',
    '🚙': 'Car',
    '🚌': 'Bus',
    '🚎': 'Trolleybus',
    '🚐': 'Minivan',
    '🚕': 'Taxi',
    '🚖': 'Taxi',
    '🚆': 'Train',
    '🚄': 'Bullet Train',
    '🚂': 'Steam Train',
    '🚊': 'Tram',
    '🚋': 'Tram',
    '🚇': 'Metro',
    '🚝': 'Monorail',
    '🚞': 'Mountain Train',
    '🚟': 'Suspension Rail',
    '🚠': 'Cable Car',
    '🚡': 'Aerial Tramway',
    '🚃': 'Railcar',
    '🚲': 'Bicycle',
    '🏍️': 'Motorcycle',
    '🛵': 'Scooter',
    '🛴': 'Kick Scooter',
    '🛹': 'Skateboard',
    '🛼': 'Roller Skates',
    '⛸️': 'Ice Skates',
    '🎿': 'Skis',
    '🛷': 'Sled',
    '🚚': 'Truck',
    '🚛': 'Semi-Truck',
    '🚜': 'Tractor',
    '🚒': 'Fire Engine',
    '🚑': 'Ambulance',
    '🚓': 'Police Car',
    '🛺': 'Auto Rickshaw',
    '🛻': 'Pickup Truck',
    '🏎️': 'Race Car',

    // Watercraft & Marine
    '🚢': 'Ship',
    '🛳️': 'Cruise Ship',
    '🚤': 'Speedboat',
    '⛵': 'Sailboat',
    '🛶': 'Canoe',
    '🚣': 'Rowboat',
    '⛴️': 'Ferry',
    '🛥️': 'Motorboat',
    '⚓': 'Anchor',
    '🛟': 'Lifebuoy',

    // Aircraft & Spacecraft
    '✈️': 'Airplane',
    '🛫': 'Takeoff',
    '🛬': 'Landing',
    '🛩️': 'Small Plane',
    '🚁': 'Helicopter',
    '🚀': 'Rocket',
    '🛸': 'Flying Saucer',
    '🎈': 'Hot Air Balloon',
    '🪂': 'Parachute',
    '🛰️': 'Satellite',

    // Pedestrians & Active Travel
    '🚶': 'Walking',
    '🚶‍♂️': 'Walking',
    '🚶‍♀️': 'Walking',
    '🏃': 'Running',
    '🚴': 'Cyclist',
    '🚵': 'Mountain Biker',
    '🧑‍🦽': 'Wheelchair',
    '🧑‍🦼': 'Electric Wheelchair',
    '🦽': 'Wheelchair',
    '🦼': 'Wheelchair',
    '🦯': 'Walking Cane',
    '🩼': 'Crutches',

    // Passengers & Transit Workers
    '👨‍👩‍👧‍👦': 'Family',
    '🧑': 'Passenger',
    '🧒': 'Child',
    '👶': 'Baby',
    '👵': 'Senior',
    '🧓': 'Elder',
    '👥': 'Passengers',
    '🧑‍✈️': 'Pilot',
    '🧑‍🚒': 'Firefighter',
    '👮': 'Police Officer',
    '👷': 'Worker',
    '🧑‍🔧': 'Mechanic',
    '🧑‍🌾': 'Farmer',
    '🧑‍⚕️': 'Doctor',
    '🧑‍🚀': 'Astronaut',

    // Transit Places & Infrastructure
    '🚏': 'Bus Stop',
    '🚉': 'Train Station',
    '🅿️': 'Parking',
    '🛣️': 'Highway',
    '🌉': 'Bridge',
    '🛤️': 'Railway Track',
    '⛽': 'Fuel Station',
    '🔌': 'EV Charger',
    '🏫': 'School',
    '🏥': 'Hospital',
    '🏠': 'Home',
    '🛃': 'Customs',
    '🛄': 'Baggage Claim',

    // Transit Safety & Signals
    '🔗': 'Seat Belt',
    '🦺': 'Safety Vest',
    '🪖': 'Helmet',
    '⛑️': 'Hard Hat',
    '🚦': 'Traffic Light',
    '🚥': 'Traffic Light',
    '🛑': 'Stop Sign',
    '⛔': 'No Entry',
    '🚳': 'No Bicycles',
    '🚷': 'No Pedestrians',
    '⚠️': 'Warning Sign',
    '🚧': 'Road Work',
    '🚸': 'School Crossing',
    '🚨': 'Siren',
    '🔔': 'Bell',
    '🎫': 'Ticket',
    '💳': 'Travel Pass',
    '🧳': 'Luggage',
    '🎒': 'Backpack',
    '🗺️': 'Map',
    '🧭': 'Compass',
    '⚙️': 'Gear',
    '🔋': 'Battery',
    '🛞': 'Tire',
    '💺': 'Seat',
    '🚪': 'Door',
    '🪞': 'Mirror',
    '💡': 'Light',
    '🏁': 'Finish Flag',

    // Historic & pack animals
    '🫏': 'Donkey',
    '🐪': 'Camel',
    '🐎': 'Horse',
    '🐕': 'Sled Dog',
    '🦮': 'Guide Dog',
    '🐂': 'Ox',

    // Infrastructure & accessibility
    '🏗️': 'Crane',
    '🛗': 'Elevator',
    '🧍': 'Pedestrian',
    '⚡': 'Electricity',
    '🛡️': 'Safety',
    '🪜': 'Ladder',
    '🛒': 'Cart',
    '🛝': 'Slide',
    '🪙': 'Coin',
    '🌧️': 'Rain',
    '☀️': 'Sunny',
    '❄️': 'Snow',
    '🌫️': 'Fog',
    '💨': 'Wind',
    '☂️': 'Umbrella',
    '🔧': 'Wrench',
    '🔨': 'Hammer',
  };

  static String getLabel(String text) {
    final label = _vocab[text.trim()];
    if (label != null) return label;
    final cleaned = text.trim();
    if (RegExp(r'^[a-zA-Z0-9\s\-\.\,\(\)]+$').hasMatch(cleaned)) {
      return cleaned;
    }
    return '';
  }

  static String getSpeechText(String text) {
    final label = getLabel(text);
    if (label.isNotEmpty) return label;
    return text.trim();
  }
}

/// Production-grade Transport & City Transit Game Layout for Kids Zone.
///
/// Features:
/// - Dual interaction: Seamless Drag-and-Drop to the highway gantry destination,
///   AND accessible tap-to-answer for younger or motor-impaired learners.
/// - Unspoiled clue display: Displays the complete educational scenario on
///   the illuminated overhead highway sign without prematurely leaking the emoji.
/// - Audio scaffolding: Pronounces target transport vocabulary clearly for ESL
///   learners on demand and upon submission, with dedicated audio buttons.
/// - Dynamic transit vehicle cards: Displays vehicle category, big emoji, and
///   clean English vocabulary label on modern tactile transit cards.
/// - Lifeline integration: Automatically dims a distractor card when `hintUsed`
///   is active to guide struggling children.
/// - Visual hierarchy & 2026 polish: Steel highway gantry, reflective green signage,
///   route shield badge, asphalt roadway with yellow dashes, and celebratory route clearance.
/// - Responsive & scroll-safe: LayoutBuilder + SingleChildScrollView guarantees
///   zero RenderFlex overflows across 320dp to tablet dimensions.
///
/// Complexity:
/// - Time Complexity: O(N) where N is options count (typically 3)
/// - Space Complexity: O(1) auxiliary space
class KidsTransportLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsTransportLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsTransportLayout> createState() => _KidsTransportLayoutState();
}

class _KidsTransportLayoutState extends State<KidsTransportLayout> {
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
    String option,
  ) {
    if (state.answerStatus.isAnswered) return;

    setState(() {
      _selectedOption = option;
    });

    final quest = state.currentQuest;
    final isCorrect = (option == quest.correctAnswer);

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'KidsTransportLayout: Submitting option "$option" for quest "${quest.id}" (correct: $isCorrect)',
      );
    }

    // Audio reinforcement: Pronounce the English vehicle/item name clearly for ESL learners
    final speechText = TransportVocabularyHelper.getSpeechText(option);
    if (speechText.isNotEmpty) {
      di.sl<KidsTTSService>().speak(speechText, force: true);
    }

    if (isCorrect) {
      di.sl<HapticService>().success();
    } else {
      di.sl<HapticService>().error();
    }

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _playOptionAudio(String text) {
    final speechText = TransportVocabularyHelper.getSpeechText(text);
    if (speechText.isNotEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'KidsTransportLayout: Pronouncing option "$speechText"',
        );
      }
      di.sl<KidsTTSService>().speak(speechText, force: true);
      di.sl<HapticService>().selection();
    }
  }

  void _replayQuestionAudio(KidsQuest quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    if (instruction.isNotEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'KidsTransportLayout: Replaying clue audio for quest "${quest.id}"',
        );
      }
      di.sl<KidsTTSService>().speak(instruction, force: true);
      di.sl<HapticService>().selection();
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
      gameType: 'transport',
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
                      SizedBox(height: KidsGameBaseScreen.mascotClearanceHeight),

                      // Overhead Highway Gantry & Destination Target
                      _buildHighwayGantry(
                        context,
                        state,
                        quest,
                        isNarrow: isNarrow,
                      ),

                      SizedBox(height: 12.h),

                      // Action Instruction Header
                      _buildInteractionPrompt(context, state),

                      SizedBox(height: 12.h),

                      // Transit Vehicle Options
                      _buildOptionsSection(
                        context,
                        state,
                        quest,
                        isNarrow: isNarrow,
                      ),

                      SizedBox(height: 16.h),

                      // Roadway Asphalt & Crosswalk Visual Accent
                      _buildRoadwaySurface(isNarrow: isNarrow),
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

  /// Overhead Highway Gantry Sign with Route Marker & Clue Display
  Widget _buildHighwayGantry(
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
              ? 'Correct vehicle: ${TransportVocabularyHelper.getLabel(quest.correctAnswer ?? '')}'
              : 'Clue: $instruction. Tap a matching vehicle or drag it to this sign.',
          button: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Steel Truss Bracket Top
              _buildGantryTrussTop(),

              // Highway Destination Sign
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isHovering
                        ? [
                            _TransportPalette.signGreenLight,
                            _TransportPalette.signGreen,
                          ]
                        : [
                            _TransportPalette.signGreen,
                            _TransportPalette.signGreenDark,
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isHovering
                        ? _TransportPalette.signHoverGlow
                        : (isCorrect
                            ? _TransportPalette.successBorder
                            : _TransportPalette.signBorder),
                    width: isHovering ? 4.5.w : 3.5.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isHovering
                              ? _TransportPalette.signHoverGlow
                              : Colors.black)
                          .withValues(alpha: isHovering ? 0.45 : 0.25),
                      blurRadius: isHovering ? 20 : 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Highway Header Bar with Route Shield & Audio
                    _buildGantryHeaderBar(quest, isNarrow: isNarrow),

                    // Clue or Solved Hero Display
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      child: isCorrect
                          ? _buildSolvedStateDisplay(quest, isNarrow: isNarrow)
                          : _buildClueStateDisplay(
                              quest,
                              instruction,
                              isHovering: isHovering,
                              isNarrow: isNarrow,
                            ),
                    ),
                  ],
                ),
              ),

              // Gantry Steel Support Posts
              _buildGantrySupportPosts(),
            ],
          ),
        );
      },
    );
  }

  /// Steel Truss Gantry Top Header
  Widget _buildGantryTrussTop() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      height: 10.h,
      decoration: BoxDecoration(
        color: _TransportPalette.gantryTruss,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(8, (index) {
          return Container(
            width: 4.w,
            height: 4.h,
            decoration: const BoxDecoration(
              color: _TransportPalette.gantryJoint,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }

  /// Gantry Support Posts Below Sign
  Widget _buildGantrySupportPosts() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSingleSupportPost(),
          _buildSingleSupportPost(),
        ],
      ),
    );
  }

  Widget _buildSingleSupportPost() {
    return Container(
      width: 14.w,
      height: 18.h,
      decoration: BoxDecoration(
        color: _TransportPalette.gantryTruss,
        border: Border.all(color: _TransportPalette.gantryJoint, width: 1.5),
      ),
    );
  }

  /// Highway Sign Header Bar (Route Shield, Title, Audio Speaker)
  Widget _buildGantryHeaderBar(KidsQuest quest, {required bool isNarrow}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Route Shield Marker
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  _TransportPalette.routeShieldBlue,
                  _TransportPalette.routeShieldRed,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: Colors.white, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.alt_route_rounded,
                  color: Colors.white,
                  size: 13,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Route ${widget.level}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Dedicated Audio Clue Replay Button
          ScaleButton(
            onTap: () => _replayQuestionAudio(quest),
            scaleDown: 0.90,
            child: Semantics(
              label: 'Listen to clue',
              button: true,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      context.tr('games.listen', fallback: 'Listen'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
  }

  /// Clue State Display: Shows Full Educational Scenario Without Leaking Answer
  Widget _buildClueStateDisplay(
    KidsQuest quest,
    String instruction, {
    required bool isHovering,
    required bool isNarrow,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scenario Text Box
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isHovering
                  ? _TransportPalette.signHoverGlow
                  : Colors.white.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: KidsFittedText(
            instruction.isEmpty
                ? 'Choose the matching vehicle.'
                : instruction,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isNarrow ? 15.sp : 16.5.sp,
              fontWeight: FontWeight.w600,
              height: 1.4,
              letterSpacing: 0.2,
              color: Colors.white,
            ),
            maxLines: 5,
            textAlign: TextAlign.left,
          ),
        ),

        SizedBox(height: 8.h),

        // Drop Zone / Tap Prompt Invitation
        Container(
          padding: EdgeInsets.symmetric(vertical: 7.h),
          decoration: BoxDecoration(
            color: isHovering
                ? _TransportPalette.signHoverGlow.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isHovering
                  ? _TransportPalette.signHoverGlow
                  : Colors.white.withValues(alpha: 0.20),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isHovering
                    ? Icons.download_rounded
                    : Icons.touch_app_rounded,
                color: isHovering
                    ? _TransportPalette.signHoverGlow
                    : Colors.white.withValues(alpha: 0.85),
                size: 14.sp,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  isHovering
                      ? context.tr(
                          'games.drop_here',
                          fallback: 'Drop here to answer',
                        )
                      : context.tr(
                          'games.kids_transport_drop_hint',
                          fallback: 'Drop here or tap below',
                        ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.5.sp,
                    fontWeight: isHovering ? FontWeight.w600 : FontWeight.w500,
                    color: isHovering
                        ? _TransportPalette.signHoverGlow
                        : Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Solved State Display: Clean Celebratory Confirmation with Correct Vehicle
  Widget _buildSolvedStateDisplay(KidsQuest quest, {required bool isNarrow}) {
    final solvedAnswer = quest.correctAnswer ?? quest.emoji ?? '';
    final label = TransportVocabularyHelper.getLabel(solvedAnswer);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Solved Confirmation Badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: _TransportPalette.successBg,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: _TransportPalette.successBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: _TransportPalette.successText,
                size: 15,
              ),
              SizedBox(width: 5.w),
              Text(
                context.tr('games.correct', fallback: 'Correct!'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: _TransportPalette.successText,
                ),
              ),
            ],
          ),
        ).animate().scale(duration: 350.ms, curve: Curves.elasticOut),

        SizedBox(height: 8.h),

        // Solved Hero Vehicle Emoji
        Text(
          solvedAnswer,
          style: TextStyle(fontSize: isNarrow ? 56.sp : 64.sp),
        )
            .animate()
            .scale(duration: 400.ms, curve: Curves.elasticOut)
            .shimmer(delay: 200.ms, duration: 800.ms),

        SizedBox(height: 4.h),

        // English Vocabulary Name
        if (label.isNotEmpty)
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isNarrow ? 19.sp : 21.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15),
      ],
    );
  }

  /// Action Prompt Banner
  Widget _buildInteractionPrompt(BuildContext context, KidsLoaded state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 15.sp,
            color: _TransportPalette.roadStripe,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              context.tr(
                'games.kids_transport_instruction',
                fallback: 'Choose the matching vehicle',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.slate700,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Transit Vehicle Options Cards
  Widget _buildOptionsSection(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required bool isNarrow,
  }) {
    final options = quest.options ?? const [];
    if (options.isEmpty) return const SizedBox.shrink();

    // Determine distractor to dim if hint was used
    String? distractorToDim;
    if (state.hintUsed) {
      for (final opt in options) {
        if (opt != quest.correctAnswer) {
          distractorToDim = opt;
          break;
        }
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(options.length, (index) {
        final option = options[index];
        final isCorrect = (option == quest.correctAnswer);
        final isDimmed = (distractorToDim == option);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: _TransitVehicleCard(
              option: option,
              isCorrect: isCorrect,
              isSelected: _selectedOption == option,
              isAnswered: state.answerStatus.isAnswered,
              isDimmed: isDimmed,
              isNarrow: isNarrow,
              onTap: () => _handleOptionSubmit(context, state, option),
              onPlayAudio: () => _playOptionAudio(option),
            ),
          ),
        );
      }),
    );
  }

  /// Asphalt Roadway Surface Visual Grounding
  Widget _buildRoadwaySurface({required bool isNarrow}) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: _TransportPalette.primaryAsphalt,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _TransportPalette.roadSurface,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Road shoulder textures
          Positioned(
            top: 4.h,
            left: 0,
            right: 0,
            child: Container(
              height: 2.h,
              color: _TransportPalette.crosswalkWhite.withValues(alpha: 0.2),
            ),
          ),
          Positioned(
            bottom: 4.h,
            left: 0,
            right: 0,
            child: Container(
              height: 2.h,
              color: _TransportPalette.crosswalkWhite.withValues(alpha: 0.2),
            ),
          ),

          // Yellow Dashed Center Line
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(isNarrow ? 6 : 8, (index) {
              return Container(
                width: isNarrow ? 22.w : 28.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: _TransportPalette.roadStripe,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Tactical Transit Vehicle Card with Dual Tap/Drag Support & Audio Speaker
class _TransitVehicleCard extends StatelessWidget {
  final String option;
  final bool isCorrect;
  final bool isSelected;
  final bool isAnswered;
  final bool isDimmed;
  final bool isNarrow;
  final VoidCallback onTap;
  final VoidCallback onPlayAudio;

  const _TransitVehicleCard({
    required this.option,
    required this.isCorrect,
    required this.isSelected,
    required this.isAnswered,
    required this.isDimmed,
    required this.isNarrow,
    required this.onTap,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final label = TransportVocabularyHelper.getLabel(option);

    // Compute Border & Background colors based on state
    Color cardBg = _TransportPalette.cardBg;
    Color borderColor = _TransportPalette.cardBorder;
    double borderWidth = 1.5;

    if (isAnswered && isSelected) {
      if (isCorrect) {
        cardBg = _TransportPalette.successBg;
        borderColor = _TransportPalette.successBorder;
        borderWidth = 2.5;
      } else {
        cardBg = _TransportPalette.errorBg;
        borderColor = _TransportPalette.errorBorder;
        borderWidth = 2.5;
      }
    }

    final cardWidget = AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isDimmed ? 0.32 : 1.0,
      child: Container(
        constraints: BoxConstraints(
          minHeight: isNarrow ? 116.h : 126.h,
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: (isAnswered && isSelected
                      ? (isCorrect
                          ? _TransportPalette.successBorder
                          : _TransportPalette.errorBorder)
                      : _TransportPalette.cardShadow)
                  .withValues(alpha: isAnswered && isSelected ? 0.25 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Bar: Audio Speaker in corner
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Semantics(
                  label: 'Pronounce $label',
                  button: true,
                  child: GestureDetector(
                    onTap: isDimmed ? null : onPlayAudio,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.volume_up_rounded,
                        size: 13.sp,
                        color: AppColors.slate600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Large Vehicle Emoji
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                option,
                style: TextStyle(
                  fontSize: isNarrow ? 38.sp : 44.sp,
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // English Vocabulary Name Label
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isNarrow ? 13.sp : 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isAnswered && isSelected
                      ? (isCorrect
                          ? _TransportPalette.successText
                          : _TransportPalette.errorText)
                      : AppColors.slate800,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              SizedBox(height: isNarrow ? 16.h : 18.h),
          ],
        ),
      ),
    );

    // If already answered or dimmed, don't allow drag or tap
    if (isAnswered || isDimmed) {
      return cardWidget;
    }

    return Semantics(
      label: 'Option: $label ($option). Tap or drag to highway gantry.',
      button: true,
      enabled: !isAnswered,
      child: ScaleButton(
        onTap: isAnswered ? null : onTap,
        scaleDown: 0.94,
        child: isAnswered
            ? cardWidget
            : Draggable<String>(
                data: option,
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: 96.w,
                    child: Transform.scale(
                      scale: 1.05,
                      child: Opacity(opacity: 0.95, child: cardWidget),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.28, child: cardWidget),
                child: cardWidget,
              ),
      ),
    );
  }
}
