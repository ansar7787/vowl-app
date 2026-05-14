import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/widgets/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WritingEmailScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const WritingEmailScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.writingEmail,
  });

  @override
  State<WritingEmailScreen> createState() => _WritingEmailScreenState();
}

class _WritingEmailScreenState extends State<WritingEmailScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  final Map<String, String?> _slots = {
    'SUBJECT': null,
    'SALUTATION': null,
    'BODY': null,
    'SIGN-OFF': null,
  };
  final Set<String> _jammedSlots = {'BODY'};
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(FetchWritingQuests(gameType: widget.gameType, level: widget.level));
  }

  void _onSlot(String slotKey, String data) {
    if (_isAnswered || _jammedSlots.contains(slotKey)) {
      if (_jammedSlots.contains(slotKey)) _hapticService.error();
      return;
    }
    _hapticService.success();
    setState(() => _slots[slotKey] = data);
  }

  void _clearJam(String slotKey) {
    if (!_jammedSlots.contains(slotKey)) return;
    _hapticService.selection();
    setState(() => _jammedSlots.remove(slotKey));
  }

  void _submitAnswer() {
    if (_isAnswered || _slots.values.any((v) => v == null)) return;
    _hapticService.success();
    _soundService.playCorrect();
    setState(() { _isAnswered = true; _isCorrect = true; });
    context.read<WritingBloc>().add(SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listener: (context, state) {
        if (state is WritingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _slots.updateAll((k, v) => null);
              _jammedSlots.clear();
              _jammedSlots.add('BODY');
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'CORRESPONDENCE ACE!', enableDoubleUp: true);
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<WritingBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final quest = (state is WritingLoaded) ? state.currentQuest : null;
        final components = [
          "URGENT: PROJECT UPDATE",
          "DEAR TEAM LEAD,",
          "I HAVE COMPLETED THE ANALYSIS.",
          "BEST REGARDS,",
        ];

        return WritingBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: quest == null ? const SizedBox() : Column(
            children: [
              SizedBox(height: 16.h),
              _buildInstruction(theme.primaryColor),
              SizedBox(height: 32.h),
              Expanded(
                child: ListView(
                  children: _slots.keys.map((k) => _buildHexSlot(k, theme.primaryColor, isDark)).toList(),
                ),
              ),
              _buildDataStream(components, theme.primaryColor),
              SizedBox(height: 32.h),
              if (!_isAnswered)
                ScaleButton(
                  onTap: _submitAnswer,
                  child: Container(
                    width: double.infinity, height: 60.h,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), color: _slots.values.every((v) => v != null) ? theme.primaryColor : Colors.grey, boxShadow: [if (_slots.values.every((v) => v != null)) BoxShadow(color: theme.primaryColor.withValues(alpha: 0.3), blurRadius: 15)]),
                    child: Center(child: Text("TRANSMIT PACKET", style: GoogleFonts.outfit(fontSize: 16.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
                  ),
                ),
              SizedBox(height: 20.h),
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
          Icon(Icons.terminal_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Text("SEQUENCE THE DATA PACKETS INTO THE NEURAL SLOTS", style: GoogleFonts.outfit(fontSize: 10.sp, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildHexSlot(String key, Color color, bool isDark) {
    bool isJammed = _jammedSlots.contains(key);
    bool hasData = _slots[key] != null;

    return GestureDetector(
      onTap: () => _clearJam(key),
      child: DragTarget<String>(
        onAcceptWithDetails: (details) => _onSlot(key, details.data),
        builder: (context, candidateData, rejectedData) {
          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isJammed ? Colors.redAccent.withValues(alpha: 0.1) : Colors.black45,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: isJammed ? Colors.redAccent : (candidateData.isNotEmpty ? Colors.white : color.withValues(alpha: 0.3)), width: 2),
            ),
            child: Row(
              children: [
                Text(key, style: GoogleFonts.shareTechMono(color: isJammed ? Colors.redAccent : color.withValues(alpha: 0.5), fontSize: 10.sp)),
                SizedBox(width: 16.w),
                Expanded(child: Text(isJammed ? "!! INTERFERENCE DETECTED !!" : (_slots[key] ?? "--- EMPTY ---"), style: GoogleFonts.outfit(color: isJammed ? Colors.redAccent : (hasData ? Colors.white : Colors.white24)))),
                if (isJammed) Icon(Icons.flash_on_rounded, color: Colors.redAccent).animate(onPlay: (c) => c.repeat()).shimmer(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDataStream(List<String> items, Color color) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((i) => Draggable<String>(
          data: i,
          feedback: Material(color: Colors.transparent, child: Container(padding: EdgeInsets.all(12.r), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8.r)), child: Text(i, style: GoogleFonts.shareTechMono(color: Colors.white)))),
          child: Container(margin: EdgeInsets.only(right: 12.w), padding: EdgeInsets.all(12.r), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8.r), border: Border.all(color: color.withValues(alpha: 0.2))), child: Text(i, style: GoogleFonts.shareTechMono(color: color, fontSize: 10.sp))),
        )).toList(),
      ),
    );
  }
}
