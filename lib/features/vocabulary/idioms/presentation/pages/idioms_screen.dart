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
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class IdiomsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const IdiomsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.idioms,
  });

  @override
  State<IdiomsScreen> createState() => _IdiomsScreenState();
}

class _IdiomsScreenState extends State<IdiomsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
  }

  void _submitAnswer(String selected, String correct) {
    if (_isAnswered) return;
    setState(() {
      _selectedOption = selected;
      _isAnswered = true;
    });

    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();
    
    Future.delayed(600.ms, () {
      if (!mounted) return;
      if (isCorrect) {
        _hapticService.success();
        _soundService.playCorrect();
        setState(() => _isCorrect = true);
        context.read<VocabularyBloc>().add(SubmitAnswer(true));
      } else {
        _hapticService.error();
        _soundService.playWrong();
        setState(() => _isCorrect = false);
        context.read<VocabularyBloc>().add(SubmitAnswer(false));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          if (state.currentIndex != _lastProcessedIndex || (_isAnswered && state.lastAnswerCorrect == null)) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedOption = null;
            });
          }
        }
        if (state is VocabularyGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'EMOJI EXPERT!',
            enableDoubleUp: true,
          );
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);
        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;
        final loadedState = state is VocabularyLoaded ? state : null;

        if (state is VocabularyLoading || (quest == null && state is! VocabularyGameComplete && state is! VocabularyError)) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: GameShimmerLoading(primaryColor: theme.primaryColor),
          );
        }

        _isAnswered = loadedState?.lastAnswerCorrect != null;
        _isCorrect = loadedState?.lastAnswerCorrect;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return VocabularyBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          useScrolling: false,
          disablePadding: true,
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GridPainter(
                          theme.primaryColor.withValues(
                            alpha: isDarkMode ? 0.05 : 0.03,
                          ),
                        ),
                      ),
                    ),
                    _buildChatInterface(quest, theme.primaryColor, isDarkMode),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildChatInterface(VocabularyQuest quest, Color color, bool isDark) {
    return Column(
      children: [
        SizedBox(height: 40.h),
        Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 8.r,
                height: 8.r,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
              SizedBox(width: 10.w),
              Text(
                "EMOJIFY: SECURE CHANNEL",
                style: GoogleFonts.shareTechMono(
                  fontSize: 10.sp,
                  color: color,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(Icons.lock_outline_rounded, size: 14.r, color: color),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            children: [
              _buildSystemMessage("INCOMING TRANSMISSION...", color),
              SizedBox(height: 20.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(Icons.psychology_alt_rounded, size: 20.r, color: color),
                  ),
                  SizedBox(width: 10.w),
                  _buildStrangerMessage(quest.topicEmoji ?? "❓", color, isDark),
                ],
              ),

              if (_selectedOption != null) ...[
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildUserMessage(_selectedOption!, color, _isCorrect, isDark),
                    SizedBox(width: 10.w),
                    CircleAvatar(
                      radius: 18.r,
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.face_retouching_natural_rounded,
                        size: 20.r,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],

              if (_isAnswered && _isCorrect == false) ...[
                SizedBox(height: 15.h),
                _buildSystemMessage("DECRYPTION FAILED. RE-EVALUATE SEQUENCE.", Colors.redAccent),
              ],
            ],
          ),
        ),
        
        _buildOptions(quest.options ?? [], quest.correctAnswer ?? "", color, isDark),
        SizedBox(height: 40.h),
      ],
    );
  }

  Widget _buildSystemMessage(String text, Color color) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Text(
          text,
          style: GoogleFonts.shareTechMono(fontSize: 9.sp, color: color, letterSpacing: 1.5, fontWeight: FontWeight.bold),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildStrangerMessage(String emojis, Color color, bool isDark) {
    return Container(
      constraints: BoxConstraints(maxWidth: 0.75.sw),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        border: Border.all(
          color: isDark ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        emojis,
        style: TextStyle(fontSize: 48.sp),
      ),
    )
    .animate()
    .slideX(begin: -0.1, duration: 500.ms, curve: Curves.easeOutCubic)
    .fadeIn();
  }

  Widget _buildUserMessage(String text, Color color, bool? isCorrect, bool isDark) {
    final bgColor = isCorrect == true ? Colors.green : (isCorrect == false ? Colors.red : color);
    return Container(
      constraints: BoxConstraints(maxWidth: 0.75.sw),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark ? bgColor.withValues(alpha: 0.15) : bgColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
          bottomLeft: Radius.circular(24.r),
        ),
        border: Border.all(color: bgColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (isCorrect != null) ...[
            SizedBox(width: 10.w),
            Icon(
              isCorrect ? Icons.verified_rounded : Icons.gpp_bad_rounded,
              color: isCorrect ? Colors.greenAccent : Colors.redAccent,
              size: 18.r,
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          ],
        ],
      ),
    )
    .animate()
    .slideX(begin: 0.1, duration: 500.ms, curve: Curves.easeOutCubic)
    .fadeIn();
  }

  Widget _buildOptions(List<String> options, String correct, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Wrap(
        spacing: 12.w,
        runSpacing: 12.h,
        alignment: WrapAlignment.center,
        children: options.map((o) {
          final isSelected = _selectedOption == o;
          final isWrong = _isAnswered && isSelected && _isCorrect == false;
          final isCorrectOption = _isAnswered && o == correct && _isCorrect == true;

          Color cardBg = isDark ? color.withValues(alpha: 0.1) : Colors.white;
          Color cardBorder = color.withValues(alpha: 0.3);
          Color textColor = isDark ? Colors.white70 : Colors.black87;

          if (isCorrectOption) {
            cardBg = Colors.green.withValues(alpha: 0.2);
            cardBorder = Colors.green;
            textColor = isDark ? Colors.white : Colors.green.shade700;
          } else if (isWrong) {
            cardBg = Colors.red.withValues(alpha: 0.2);
            cardBorder = Colors.red;
            textColor = isDark ? Colors.white : Colors.red.shade700;
          } else if (isSelected) {
            cardBg = color.withValues(alpha: 0.3);
            cardBorder = color;
            textColor = isDark ? Colors.white : color;
          }

          return ScaleButton(
            onTap: () => _submitAnswer(o, correct),
            child: AnimatedContainer(
              duration: 300.ms,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(color: cardBorder, width: 1.5),
                boxShadow: [
                  if (isSelected || isCorrectOption)
                    BoxShadow(
                      color: cardBorder.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                ],
              ),
              child: Text(
                o.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    )
    .animate()
    .fadeIn(delay: 800.ms)
    .slideY(begin: 0.3, curve: Curves.easeOutCubic);
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
