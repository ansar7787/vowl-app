import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_base_layout.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';


class DialectDrillScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DialectDrillScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.dialectDrill,
  });

  @override
  State<DialectDrillScreen> createState() => _DialectDrillScreenState();
}

class _DialectDrillScreenState extends State<DialectDrillScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  Offset _pinPosition = Offset.zero;
  int? _hoveredTowerIndex;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onPinDragUpdate(DragUpdateDetails details) {
    if (_isAnswered) return;
    setState(() {
      _pinPosition += details.delta;
    });
    
    // Check tower proximity
    _checkTowerHover();
  }

  void _checkTowerHover() {
    // Simplified collision detection for the demo
    double centerX = 1.sw / 2;
    if ((_pinPosition.dx - (centerX - 100.w)).abs() < 50.r) {
       setState(() => _hoveredTowerIndex = 0);
    } else if ((_pinPosition.dx - (centerX + 100.w)).abs() < 50.r) {
       setState(() => _hoveredTowerIndex = 1);
    } else {
       setState(() => _hoveredTowerIndex = null);
    }
  }

  void _onPinDragEnd() {
    if (_isAnswered || _hoveredTowerIndex == null) {
      setState(() => _pinPosition = Offset.zero);
      return;
    }
    _submitAnswer(_hoveredTowerIndex!, context.read<AccentBloc>().state is AccentLoaded ? (context.read<AccentBloc>().state as AccentLoaded).currentQuest.correctAnswerIndex ?? 0 : 0);
  }

  void _submitAnswer(int index, int correct) {
    if (_isAnswered) return;
    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _pinPosition = Offset.zero;
              _hoveredTowerIndex = null;
            });
          }
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'DIALECT EXPERT!', enableDoubleUp: true);
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<AccentBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is AccentLoaded) ? state.currentQuest : null;

        return AccentBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
          onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
          child: quest == null ? const SizedBox() : Stack(
            alignment: Alignment.center,
            children: [
              _buildInstruction(theme.primaryColor),
              _buildDialectHeader(quest.textToSpeak ?? "", theme.primaryColor, isDark),
              _buildTopographicMap(theme.primaryColor, isDark),
              if (!_isAnswered) _buildDataPin(theme.primaryColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstruction(Color color) {
    return Positioned(
      top: 20.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30.r), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Text("DROP THE DATA PIN ON THE MATCHING REGIONAL TOWER", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildDialectHeader(String text, Color color, bool isDark) {
    return Positioned(
      top: 80.h,
      child: Column(
        children: [
          ScaleButton(
            onTap: () => _soundService.playTts(text),
            child: Icon(Icons.public_rounded, color: color, size: 40.r),
          ),
          SizedBox(height: 12.h),
          Text(text, textAlign: TextAlign.center, style: GoogleFonts.fredoka(fontSize: 24.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTopographicMap(Color color, bool isDark) {
    return Center(
      child: Container(
        width: 0.9.sw, height: 400.h,
        decoration: BoxDecoration(
          color: isDark ? Colors.black38 : Colors.white12,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
             // Regional Towers
             _buildTower(0, "REGIONAL A", Offset(-100.w, 0), color),
             _buildTower(1, "REGIONAL B", Offset(100.w, 0), color),
          ],
        ),
      ),
    );
  }

  Widget _buildTower(int index, String label, Offset offset, Color color) {
    bool isHovered = _hoveredTowerIndex == index;
    return Transform.translate(
      offset: offset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_input_antenna_rounded, size: 64.r, color: isHovered ? color : color.withValues(alpha: 0.3))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: (1 + index).seconds),
          SizedBox(height: 8.h),
          Text(label, style: GoogleFonts.shareTechMono(fontSize: 12.sp, color: color)),
        ],
      ),
    );
  }

  Widget _buildDataPin(Color color) {
    return Positioned(
      bottom: 60.h,
      child: GestureDetector(
        onPanUpdate: _onPinDragUpdate,
        onPanEnd: (_) => _onPinDragEnd(),
        child: Transform.translate(
          offset: _pinPosition,
          child: Icon(Icons.location_on_rounded, color: color, size: 60.r)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -5, end: 5),
        ),
      ),
    );
  }
}
