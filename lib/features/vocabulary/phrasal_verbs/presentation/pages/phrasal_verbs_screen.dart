import 'dart:math';
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

class PhrasalVerbsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PhrasalVerbsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.phrasalVerbs,
  });

  @override
  State<PhrasalVerbsScreen> createState() => _PhrasalVerbsScreenState();
}

class _PhrasalVerbsScreenState extends State<PhrasalVerbsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final List<Offset> _bubbleOffsets = [];
  int? _poppedIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
    _initBubbles();
  }

  void _initBubbles() {
    final rand = Random();
    _bubbleOffsets.clear();
    for (int i = 0; i < 6; i++) {
      _bubbleOffsets.add(Offset(rand.nextDouble() * 300 - 150, rand.nextDouble() * 100));
    }
  }

  void _onPop(int index, String selected, String correct) {
    if (_isAnswered) return;
    _hapticService.success();
    setState(() => _poppedIndex = index);

    bool isCorrect = selected.trim().toLowerCase() == correct.trim().toLowerCase();
    
    final bloc = context.read<VocabularyBloc>();
    Future.delayed(400.ms, () {
      if (!context.mounted) return;
      if (isCorrect) {
        _soundService.playCorrect();
        setState(() { _isAnswered = true; _isCorrect = true; });
        bloc.add(SubmitAnswer(true));
      } else {
        _soundService.playWrong();
        setState(() { _isAnswered = true; _isCorrect = false; });
        bloc.add(SubmitAnswer(false));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listener: (context, state) {
        if (state is VocabularyLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = state.lastAnswerCorrect == null && _isAnswered;

          if (isNewQuestion || isRetry) {
            setState(() {
              _lastQuest = state.currentQuest;
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _poppedIndex = null;
              _initBubbles();
            });
          }
        }
        if (state is VocabularyGameComplete) {
          final xp = state.xpEarned;
          final coins = state.coinsEarned;
          setState(() => _showConfetti = true);
          if (!context.mounted) return;
          GameDialogHelper.showCompletion(
            context,
            xp: xp,
            coins: coins,
            title: 'PHRASAL VORTEX!',
            enableDoubleUp: true,
          );
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;
        if (quest == null && state is! VocabularyGameComplete) return const GameShimmerLoading();
        final verb = quest?.word?.split(' ')[0] ?? "???";
        final options = quest?.options ?? [];

        return VocabularyBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildVerbVortex(verb, theme.primaryColor, isDark),
              ...List.generate(options.length, (i) => _buildParticleBubble(i, options[i], quest.correctAnswer ?? "", theme.primaryColor, isDark)),
              Positioned(top: 20.h, child: _buildInstruction(theme.primaryColor)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bubble_chart_rounded, size: 14.r, color: color),
          SizedBox(width: 8.w),
          Text("POP THE PARTICLE INTO THE VORTEX", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildVerbVortex(String verb, Color color, bool isDark) {
    return Positioned(
      top: 100.h,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(verb.toUpperCase(), style: GoogleFonts.outfit(fontSize: 40.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 5)),
              SizedBox(width: 20.w),
              Container(
                width: 100.w, height: 60.h,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: color, width: 2), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20)]),
                child: Center(
                  child: _isAnswered 
                    ? Text(_isCorrect == true ? "!" : "?", style: GoogleFonts.outfit(fontSize: 30.sp, color: _isCorrect == true ? Colors.greenAccent : Colors.redAccent))
                    : Icon(Icons.auto_fix_high_rounded, color: color.withValues(alpha: 0.3)),
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticleBubble(int index, String text, String correct, Color color, bool isDark) {
    bool isPopped = _poppedIndex == index;
    final pos = _bubbleOffsets[index];

    return Positioned(
      bottom: 100.h + pos.dy,
      left: 150.w + pos.dx,
      child: GestureDetector(
        onTap: () => _onPop(index, text, correct),
        child: AnimatedContainer(
          duration: 400.ms,
          curve: Curves.easeInBack,
          transform: isPopped ? (Matrix4.identity()..setTranslationRaw(0.0, -300.h, 0.0)) : Matrix4.identity(),
          child: Opacity(
            opacity: isPopped ? 0.0 : 1.0,
            child: Container(
              width: 80.r, height: 80.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0.1)], center: const Alignment(-0.3, -0.3)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10)],
              ),
              child: Center(
                child: Text(text.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 12.sp, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat()).moveY(begin: -5, end: 5, duration: 2.seconds).shake(hz: 1, curve: Curves.easeInOut),
        ),
      ),
    );
  }
}

