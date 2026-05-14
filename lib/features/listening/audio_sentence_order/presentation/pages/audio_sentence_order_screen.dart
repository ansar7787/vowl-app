import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/widgets/listening_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AudioSentenceOrderScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AudioSentenceOrderScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.audioSentenceOrder,
  });

  @override
  State<AudioSentenceOrderScreen> createState() =>
      _AudioSentenceOrderScreenState();
}

class _AudioSentenceOrderScreenState extends State<AudioSentenceOrderScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  List<String> _slots = [];
  List<String> _segments = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(
      FetchListeningQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onSnap(String segment, int slotIndex) {
    if (_isAnswered) return;
    setState(() {
      _slots[slotIndex] = segment;
      _segments.remove(segment);
      _hapticService.selection();
    });
  }

  void _onUnsnap(int slotIndex) {
    if (_isAnswered) return;
    setState(() {
      String segment = _slots[slotIndex];
      if (segment.isNotEmpty) {
        _segments.add(segment);
        _slots[slotIndex] = "";
        _hapticService.selection();
      }
    });
  }

  void _submitAnswer(String correctFull) {
    if (_isAnswered) return;
    String current = _slots.join(" ").trim().toLowerCase();
    String target = correctFull
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim()
        .toLowerCase();
    bool isCorrect = current == target;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<ListeningBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<ListeningBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: (context, state) {
        if (state is ListeningLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _segments = List.from(state.currentQuest.shuffledSentences ?? []);
              _slots = List.generate(_segments.length, (_) => "");
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SEQUENCE MASTER!',
            enableDoubleUp: true,
          );
        } else if (state is ListeningGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<ListeningBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;

        return ListeningBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          useScrolling: false,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Column(
                  children: [
                    const Spacer(flex: 1),
                    _buildInstruction(theme.primaryColor),
                    const Spacer(flex: 2),
                    _buildOscilloscope(
                      quest.textToSpeak ?? "",
                      theme.primaryColor,
                    ),
                    const Spacer(flex: 2),
                    Expanded(
                      flex: 4,
                      child: SingleChildScrollView(child: _buildTimeline(theme.primaryColor, isDark)),
                    ),
                    const Spacer(flex: 2),
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(child: _buildSegmentsField(theme.primaryColor, isDark)),
                    ),
                    const Spacer(flex: 2),
                    if (!_isAnswered)
                      ScaleButton(
                        onTap: () => _submitAnswer(quest.textToSpeak ?? ""),
                        child: Container(
                          width: double.infinity,
                          height: 65.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            color: theme.primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              "CALIBRATE SIGNAL",
                              style: GoogleFonts.outfit(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: 24.h),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildInstruction(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.waves_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text(
            "SNAP SEGMENTS TO TIMELINE",
            style: GoogleFonts.outfit(
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: primaryColor,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOscilloscope(String tts, Color color) {
    return ScaleButton(
      onTap: () {
        _soundService.playTts(tts);
        _hapticService.selection();
      },
      child: Container(
        height: 100.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(
              20,
              (i) =>
                  Container(
                        width: 4.w,
                        height: 20.h + (i % 5 * 10).h,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleY(
                        begin: 0.5,
                        end: 1.5,
                        duration: 500.ms,
                        delay: (i * 50).ms,
                      ),
            ),
            Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white,
              size: 48.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(Color color, bool isDark) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      alignment: WrapAlignment.center,
      children: List.generate(
        _slots.length,
        (index) => DragTarget<String>(
          onAcceptWithDetails: (details) => _onSnap(details.data, index),
          builder: (context, candidateData, rejectedData) => GestureDetector(
            onTap: () => _onUnsnap(index),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: _slots[index].isEmpty
                    ? color.withValues(alpha: 0.05)
                    : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: _slots[index].isEmpty
                      ? color.withValues(alpha: 0.2)
                      : color,
                ),
              ),
              child: Text(
                _slots[index].isEmpty ? "???" : _slots[index],
                style: GoogleFonts.shareTechMono(
                  fontSize: 14.sp,
                  color: _slots[index].isEmpty ? Colors.grey : color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentsField(Color color, bool isDark) {
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: _segments
          .map(
            (s) => Draggable<String>(
              data: s,
              feedback: Material(
                color: Colors.transparent,
                child: _buildSegmentChip(s, color, true),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildSegmentChip(s, color, false),
              ),
              child: GestureDetector(
                onTap: () {
                  if (_isAnswered) return;
                  int firstEmptyIndex = _slots.indexOf("");
                  if (firstEmptyIndex != -1) {
                    _onSnap(s, firstEmptyIndex);
                  }
                },
                child: _buildSegmentChip(s, color, false),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSegmentChip(String text, Color color, bool isFeedback) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isFeedback ? color : Colors.white10,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: isFeedback
            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)]
            : [],
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: isFeedback ? Colors.white : color,
        ),
      ),
    );
  }
}
