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

class AcademicWordScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AcademicWordScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.academicWord,
  });

  @override
  State<AcademicWordScreen> createState() => _AcademicWordScreenState();
}

class _AcademicWordScreenState extends State<AcademicWordScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final List<String> _assembledModules = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onModuleSnap(String module, String fullWord) {
    if (_isAnswered) return;
    _hapticService.success();
    setState(() => _assembledModules.add(module));

    String assembled = _assembledModules.join('').toLowerCase();
    String target = fullWord.trim().toLowerCase();

    if (assembled == target) {
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else if (assembled.length >= target.length) {
       _hapticService.error();
       _soundService.playWrong();
       setState(() { _isAnswered = true; _isCorrect = false; });
       context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
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
              _assembledModules.clear();
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
            title: 'ACADEMIC SCHOLAR!',
            enableDoubleUp: true,
          );
        } else if (state is VocabularyGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<VocabularyBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is VocabularyLoaded) ? state.currentQuest : _lastQuest;
        if (quest == null && state is! VocabularyGameComplete) return const GameShimmerLoading();
        final options = quest?.options ?? [];
        final definition = quest?.passage ?? "???";

        return VocabularyBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<VocabularyBloc>().add(NextQuestion()),
          onHint: () => context.read<VocabularyBloc>().add(VocabularyHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 24.h),
              _buildDefinitionCard(definition, theme.primaryColor, isDark),
              SizedBox(height: 40.h),
              _buildAssemblyRail(_assembledModules, theme.primaryColor, isDark),
              const Spacer(),
              _buildDraftingTray(options, (m) => _onModuleSnap(m, quest.word ?? ""), theme.primaryColor, isDark),
              SizedBox(height: 20.h),
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
      child: Text("SNAP MODULES ONTO THE RAIL", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
    );
  }

  Widget _buildDefinitionCard(String text, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.r),
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 16.sp, color: isDark ? Colors.white70 : Colors.black87, height: 1.5)),
    );
  }

  Widget _buildAssemblyRail(List<String> modules, Color color, bool isDark) {
    return Container(
      height: 80.h, width: 340.w,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Magnetic track line
          SizedBox(height: 2.h, width: 300.w, child: ColoredBox(color: color.withValues(alpha: 0.3))),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: modules.map((m) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4.r)),
              child: Text(m.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ).animate().scale().shimmer()).toList(),
          ),
          if (modules.isEmpty)
             Text("PLACE MODULES HERE", style: GoogleFonts.outfit(fontSize: 10.sp, color: color.withValues(alpha: 0.3), fontWeight: FontWeight.bold, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildDraftingTray(List<String> options, Function(String) onSnap, Color color, bool isDark) {
    return Wrap(
      spacing: 12.w, runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: options.map((m) => GestureDetector(
        onTap: () => onSnap(m),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Text(m.toUpperCase(), style: GoogleFonts.shareTechMono(fontSize: 14.sp, fontWeight: FontWeight.bold, color: color)),
        ),
      )).toList(),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}

