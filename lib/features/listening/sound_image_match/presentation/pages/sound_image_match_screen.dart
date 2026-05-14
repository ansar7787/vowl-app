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
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SoundImageMatchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SoundImageMatchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.soundImageMatch,
  });

  @override
  State<SoundImageMatchScreen> createState() => _SoundImageMatchScreenState();
}

class _SoundImageMatchScreenState extends State<SoundImageMatchScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  Offset _lensPosition = const Offset(150, 150);
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ListeningBloc>().add(FetchListeningQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onScan(Offset position) {
    if (_isAnswered) return;
    setState(() {
      _lensPosition = position;
      _hapticService.selection();
    });
  }

  void _submitAnswer(int index, int correct) {
    if (_isAnswered) return;
    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<ListeningBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
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
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _lensPosition = const Offset(150, 150);
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ListeningGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'THEMATIC LINKER!', enableDoubleUp: true);
        } else if (state is ListeningGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<ListeningBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;
        
        return ListeningBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<ListeningBloc>().add(NextQuestion()),
          onHint: () => context.read<ListeningBloc>().add(ListeningHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 32.h),
              _buildEmitter(quest.textToSpeak ?? "", theme.primaryColor),
              SizedBox(height: 40.h),
              _buildScannerField(quest.options ?? [], quest.correctAnswerIndex ?? 0, theme.primaryColor, isDark),
              const Spacer(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: primaryColor.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.biotech_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("SCAN ENCRYPTED DATA TO MATCH THE SOUND", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildEmitter(String tts, Color color) {
    return ScaleButton(
      onTap: () {
        _soundService.playTts(tts);
        _hapticService.selection();
      },
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Icon(Icons.stream_rounded, color: color, size: 48.r),
      ),
    );
  }

  Widget _buildScannerField(List<String> options, int correct, Color color, bool isDark) {
    return SizedBox(
      height: 400.h, width: double.infinity,
      child: Stack(
        children: [
          // The Options Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 16.w, mainAxisSpacing: 16.h, childAspectRatio: 1.2
            ),
            itemCount: options.length,
            itemBuilder: (context, index) => _buildEncryptedTile(index, options[index], correct, color, isDark),
          ),
          
          // The Scanning Lens
          Positioned(
            left: _lensPosition.dx - 50.r,
            top: _lensPosition.dy - 50.r,
            child: GestureDetector(
              onPanUpdate: (details) => _onScan(_lensPosition + details.delta),
              child: Container(
                width: 100.r, height: 100.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.cyanAccent, width: 3),
                  boxShadow: [BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 5)],
                ),
                child: Center(child: Icon(Icons.filter_center_focus_rounded, color: Colors.cyanAccent, size: 24.r)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncryptedTile(int index, String text, int correct, Color color, bool isDark) {
    double dist = (Offset(_lensPosition.dx, _lensPosition.dy) - Offset((index % 2 == 0 ? 80.w : 240.w), (index < 2 ? 60.h : 200.h))).distance;
    bool isRevealed = dist < 60.r;

    return GestureDetector(
      onDoubleTap: () => _submitAnswer(index, correct),
      child: GlassTile(
        padding: EdgeInsets.all(16.r), borderRadius: BorderRadius.circular(20.r),
        color: Colors.white.withValues(alpha: 0.05),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isRevealed || _isAnswered)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getCategoryIcon(text), color: color, size: 32.r),
                  SizedBox(height: 8.h),
                  Text(text.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.w900, color: color)),
                ],
              ),
            if (!isRevealed && !_isAnswered)
              Icon(Icons.security_rounded, color: Colors.white24, size: 32.r),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fruits': return Icons.apple_rounded;
      case 'tools': return Icons.build_rounded;
      case 'vehicles': return Icons.directions_car_rounded;
      case 'professions': return Icons.work_rounded;
      case 'animals': return Icons.pets_rounded;
      case 'places': return Icons.location_on_rounded;
      default: return Icons.category_rounded;
    }
  }
}

