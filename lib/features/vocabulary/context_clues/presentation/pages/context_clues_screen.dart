import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/widgets/vocabulary_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/context_clues/presentation/widgets/context_clues_painters.dart';
import 'package:vowl/features/vocabulary/context_clues/presentation/widgets/context_clues_scanner.dart';
import 'package:vowl/features/vocabulary/context_clues/presentation/widgets/context_clues_evidence_tags.dart';

class ContextCluesScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ContextCluesScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.contextClues,
  });

  @override
  State<ContextCluesScreen> createState() => _ContextCluesScreenState();
}

class _ContextCluesScreenState extends State<ContextCluesScreen>
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<Offset> _lensPosition = ValueNotifier(Offset.zero);
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;
  String? _selectedOption;

  // Clue discovery tracking
  final Set<int> _discoveredClues = {};

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(
      FetchVocabularyQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _lensPosition.dispose();
    super.dispose();
  }

  void _onLensMove(DragUpdateDetails details, BoxConstraints constraints) {
    if (_isAnswered) return;

    final double halfWidth = constraints.maxWidth / 2;
    final double halfHeight = constraints.maxHeight / 2;
    final double padding = 90.r;

    // Keep lens safely inside Paper dossier boundaries
    double newX = (_lensPosition.value.dx + details.delta.dx).clamp(
      -halfWidth + padding,
      halfWidth - padding,
    );
    double newY = (_lensPosition.value.dy + details.delta.dy).clamp(
      -halfHeight + padding,
      halfHeight - padding,
    );

    _lensPosition.value = Offset(newX, newY);

    // Simulate finding a clue (simple probability for effect, or based on position)
    if (_lensPosition.value.distance % 40 < 5) {
      _hapticService.selection();
    }
  }

  void _submitAnswer(String selected, String correct) {
    if (_isAnswered) return;

    setState(() {
      _selectedOption = selected;
      _isAnswered = true;
    });

    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    // Delay feedback to allow user to see their selection
    Future.delayed(400.ms, () {
      if (!mounted) return;

      if (isCorrect) {
        _hapticService.success();
        _soundService.playCorrect();
      } else {
        _hapticService.error();
        _soundService.playWrong();
      }

      setState(() => _isCorrect = isCorrect);
      context.read<VocabularyBloc>().add(SubmitAnswer(isCorrect));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;

          if (isNewQuestion || isRetry) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedOption = null;
              _lensPosition.value = Offset.zero;
              _discoveredClues.clear();
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'FORENSIC ANALYSIS COMPLETE!',
            enableDoubleUp: true,
          );
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

        if (state is VocabularyLoading ||
            (state is! VocabularyGameComplete &&
                state is! VocabularyLoaded &&
                state is! VocabularyError)) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () {
            final currentState = context.read<VocabularyBloc>().state;
            if (currentState is VocabularyLoaded &&
                !currentState.isFinalFailure &&
                _isCorrect == false) {
              // Mastery Loop: Retry the same question
              setState(() {
                _isAnswered = false;
                _isCorrect = null;
                _selectedOption = null;
              });
            } else {
              // Progress to next question
              context.read<VocabularyBloc>().add(NextQuestion());
            }
          },
          onHint: () =>
              context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          useScrolling: false,
          child: quest == null
              ? const SizedBox()
              : _buildForensicScene(
                  quest,
                  theme.primaryColor,
                  (state is VocabularyLoaded) ? state.isFinalFailure : false,
                ),
        );
      },
    );
  }

  Widget _buildForensicScene(
    VocabularyQuest quest,
    Color color,
    bool isFinalFailure,
  ) {
    return Column(
      children: [
        // Header
        _buildCaseHeader(color),
        SizedBox(height: 10.h),
        Text(
          "DRAG LENS TO REVEAL CLUES",
          style: GoogleFonts.shareTechMono(
            fontSize: 9.sp,
            color: color.withValues(alpha: 0.4),
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 20.h),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 1. The Paper/Case File Background
                  Positioned.fill(child: _buildCaseFileBackground()),

                  // 2. The Evidence Sentence
                  _buildEvidenceSentence(quest.sentence ?? "", color),

                  // 3. The Interactive Scanner
                  if (!_isAnswered)
                    ValueListenableBuilder<Offset>(
                      valueListenable: _lensPosition,
                      builder: (context, pos, _) {
                        return Positioned(
                          left: (constraints.maxWidth / 2) + pos.dx - 90.r,
                          top: (constraints.maxHeight / 2) + pos.dy - 90.r,
                          child: GestureDetector(
                            onPanUpdate: (d) => _onLensMove(d, constraints),
                            child: ContextCluesScanner(color: color),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),

        // 4. Evidence Tags (Options)
        ContextCluesEvidenceTags(
          options: quest.options ?? [],
          correct: quest.correctAnswer ?? "",
          color: color,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          selectedOption: _selectedOption,
          isFinalFailure: isFinalFailure,
          onOptionSelected: (o) => _submitAnswer(o, quest.correctAnswer ?? ""),
        ),
        SizedBox(height: 30.h),
      ],
    );
  }

  Widget _buildCaseHeader(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Column(
        children: [
          Text(
            "LINGUISTIC FORENSIC UNIT",
            style: GoogleFonts.oswald(
              fontSize: 10.sp,
              letterSpacing: 5,
              color: color.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40.w,
                height: 1,
                color: color.withValues(alpha: 0.2),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Text(
                  "CASE #${widget.level}-${_lastProcessedIndex + 1}",
                  style: GoogleFonts.shareTechMono(
                    fontSize: 12.sp,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                width: 40.w,
                height: 1,
                color: color.withValues(alpha: 0.2),
              ),
            ],
          ),
        ],
      ).animate().fadeIn().slideY(begin: -0.2),
    );
  }

  Widget _buildCaseFileBackground() {
    return Container(
      margin: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(painter: PaperGridPainter()),
    );
  }

  final GlobalKey _sentenceKey = GlobalKey();

  Widget _buildEvidenceSentence(String sentence, Color color) {
    final parts = sentence.split("[TARGET]");

    return Container(
      key: _sentenceKey,
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: ValueListenableBuilder<Offset>(
        valueListenable: _lensPosition,
        builder: (context, pos, _) {
          return RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                _buildTextSpan(parts[0], pos, color, _sentenceKey),
                WidgetSpan(
                  child: _buildRedactedBlock(color),
                  alignment: PlaceholderAlignment.middle,
                ),
                if (parts.length > 1)
                  _buildTextSpan(parts[1], pos, color, _sentenceKey),
              ],
            ),
          );
        },
      ),
    );
  }

  TextSpan _buildTextSpan(
    String text,
    Offset lensPos,
    Color color,
    GlobalKey parentKey,
  ) {
    final words = text.split(" ");
    return TextSpan(
      children: words.map((word) {
        return TextSpan(
          text: "$word ",
          style: GoogleFonts.specialElite(
            fontSize: 20.sp,
            height: 1.6,
            color: Colors.black.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRedactedBlock(Color color) {
    if (_isAnswered) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: _isCorrect == true
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          border: Border.all(
            color: _isCorrect == true ? Colors.green : Colors.red,
            width: 1,
          ),
        ),
        child: Text(
          _selectedOption?.toUpperCase() ?? "???",
          style: GoogleFonts.specialElite(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: _isCorrect == true ? Colors.green : Colors.red,
          ),
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut);
    }

    return Container(
          width: 100.w,
          height: 24.h,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(2.r),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 2.seconds, color: Colors.white10);
  }
}


