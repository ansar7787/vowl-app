import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_painters.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_instruction.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_thesis_paper.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_shard.dart';

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

class _AcademicWordScreenState extends State<AcademicWordScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  VocabularyQuest? _lastQuest;

  // Thesis Thrust State
  Offset _dragOffset = Offset.zero;
  int? _activeShardIndex;
  final GlobalKey _slotKey = GlobalKey();
  BoxConstraints? _lastConstraints;

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(FetchVocabularyQuests(gameType: widget.gameType, level: widget.level));
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
              _dragOffset = Offset.zero;
              _activeShardIndex = null;
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
            title: 'THESIS COMPLETE!',
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

        final isDark = Theme.of(context).brightness == Brightness.dark;

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
              : LayoutBuilder(
                  builder: (context, constraints) {
                    _lastConstraints = constraints;
                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: GridPainter(
                                theme.primaryColor.withValues(
                                  alpha: isDark ? 0.05 : 0.03,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 130.h,
                          child: AcademicWordThesisPaper(
                            passage: quest.passage ?? "",
                            color: theme.primaryColor,
                            isDark: isDark,
                            slotKey: _slotKey,
                            isAnswered: _isAnswered,
                            isCorrect: _isCorrect,
                            correctAnswer: quest.correctAnswer,
                          ),
                        ),

                        ...List.generate(quest.options?.length ?? 0, (i) {
                          return AcademicWordShard(
                            index: i,
                            text: quest.options![i],
                            color: theme.primaryColor,
                            isDark: isDark,
                            isDragging: _activeShardIndex == i,
                            offset: _dragOffset,
                            constraints: constraints,
                            onTap: () => _attemptThrust(i, quest),
                            onDragStart: (_) => _onShardDragStart(i),
                            onDragUpdate: (d) => _onShardDragUpdate(i, d),
                            onDragEnd: (_) => _onShardDragEnd(i, quest),
                            initialPosition: _getShardInitialPosition(i, quest.options?.length ?? 4),
                          );
                        }),

                        Positioned(
                          top: 50.h,
                          child: AcademicWordInstruction(color: theme.primaryColor),
                        ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
  void _onShardDragStart(int index) {
    if (_isAnswered) return;
    setState(() => _activeShardIndex = index);
    _hapticService.light();
  }

  void _onShardDragUpdate(int index, DragUpdateDetails details) {
    if (_isAnswered || _activeShardIndex != index) return;
    setState(() => _dragOffset += details.delta);
    if (_isNearSlot()) _hapticService.selection();
  }

  bool _isNearSlot() {
    if (_activeShardIndex == null || _lastConstraints == null) return false;
    
    final RenderBox? slotBox = _slotKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? stackBox = context.findRenderObject() as RenderBox?;
    
    if (slotBox == null || stackBox == null) return false;
    
    // Get target position relative to the Stack's center
    final slotPos = slotBox.localToGlobal(Offset.zero, ancestor: stackBox);
    final stackCenter = stackBox.size.center(Offset.zero);
    final targetCenter = slotPos + slotBox.size.center(Offset.zero);
    final targetOffsetFromCenter = targetCenter - stackCenter;
    
    final currentPos = _getShardCurrentPosition(_activeShardIndex!);
    
    // Check distance between shard center and slot center
    return (currentPos - targetOffsetFromCenter).distance < 80.r;
  }

  void _onShardDragEnd(int index, VocabularyQuest quest) {
    if (_isAnswered || _activeShardIndex != index) return;
    if (_isNearSlot()) {
      _attemptThrust(index, quest);
    } else {
      setState(() {
        _dragOffset = Offset.zero;
        _activeShardIndex = null;
      });
      _hapticService.light();
    }
  }

  void _attemptThrust(int index, VocabularyQuest quest) {
    final selected = quest.options![index].trim().toLowerCase();
    final correct = quest.correctAnswer?.trim().toLowerCase() ?? "";

    if (selected == correct) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
        _activeShardIndex = null;
      });
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _activeShardIndex = null;
        _dragOffset = Offset.zero;
      });
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  Offset _getShardCurrentPosition(int index) {
    final initial = _getShardInitialPosition(index, (_lastQuest?.options?.length ?? 4));
    return initial + _dragOffset;
  }

  Offset _getShardInitialPosition(int index, int total) {
    final vStep = 90.h;
    final hStep = 160.w;
    final startY = 160.h; // Relative to center
    
    // 2x2 Grid Layout
    final row = index ~/ 2;
    final col = index % 2;
    
    final x = (col == 0) ? -hStep / 2 : hStep / 2;
    final y = startY + (row * vStep);
    
    return Offset(x, y);
  }
}
