import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_blueprint_tree.dart';

/// Zero-stress Learn Phase screen for Topic Vocab ("Topic Vocab Lab").
/// Explores thematic boundaries, word definitions, phonetic pronunciations,
/// and collocations without timer or life penalties.
class TopicVocabLearnScreen extends StatefulWidget {
  final int level;
  final List<Map<String, dynamic>>? initialQuests;

  const TopicVocabLearnScreen({
    super.key,
    required this.level,
    this.initialQuests,
  });

  @override
  State<TopicVocabLearnScreen> createState() => _TopicVocabLearnScreenState();
}

class _TopicVocabLearnScreenState extends State<TopicVocabLearnScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _quests = [];
  bool _isLoading = true;
  late final HapticService _hapticService =
      di.sl.isRegistered<HapticService>() ? di.sl<HapticService>() : HapticService();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuests != null && widget.initialQuests!.isNotEmpty) {
      _quests = List.from(widget.initialQuests!);
      _isLoading = false;
    } else {
      _loadCurriculum();
    }
  }

  int get _batchStart => ((widget.level - 1) ~/ 10) * 10 + 1;
  int get _batchEnd => _batchStart + 9;

  Future<void> _loadCurriculum() async {
    final batchPath = 'assets/curriculum/vocabulary/topicVocab_learn_${_batchStart}_$_batchEnd.json';
    try {
      final jsonString = await rootBundle.loadString(batchPath);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawQuests = (data['quests'] as List<dynamic>).cast<Map<String, dynamic>>();

      final filtered = rawQuests.where((q) => (q['level'] as int? ?? widget.level) == widget.level).toList();

      if (mounted) {
        setState(() {
          _quests = filtered.isNotEmpty ? filtered : _buildFallbackQuests();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quests = _buildFallbackQuests();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildFallbackQuests() {
    return [
      {
        'id': 'VOC_TOPICVOCAB_L${widget.level}_LEARN_FALLBACK',
        'level': widget.level,
        'conceptTitle': 'Thematic Domains: Discovery L${widget.level}',
        'topicEmoji': '🏷️',
        'topicBuckets': ['Primary Domain', 'Secondary Domain'],
        'contrastInsight': 'Notice differences between primary and secondary domains.',
        'categories': [
          {
            'name': 'Primary Domain',
            'emoji': '🔹',
            'desc': 'Core fundamental vocabulary terms.',
            'words': [
              {'word': 'Anchor', 'ipa': '/ˈæŋ.kər/', 'def': 'A central, stabilizing concept or object.', 'coll': 'firm anchor', 'int': 'Base'},
              {'word': 'Pillar', 'ipa': '/ˈpɪl.ər/', 'def': 'A prominent supporting feature.', 'coll': 'central pillar', 'int': 'Support'},
              {'word': 'Bedrock', 'ipa': '/ˈbed.rɒk/', 'def': 'The solid fundamental foundation.', 'coll': 'solid bedrock', 'int': 'Foundation'}
            ]
          },
          {
            'name': 'Secondary Domain',
            'emoji': '🔸',
            'desc': 'Dynamic or expressive terms in this context.',
            'words': [
              {'word': 'Vortex', 'ipa': '/ˈvɔː.teks/', 'def': 'A whirling mass of fluid or air.', 'coll': 'polar vortex', 'int': 'Dynamic'},
              {'word': 'Ripple', 'ipa': '/ˈrɪp.əl/', 'def': 'A small wave or series of waves.', 'coll': 'ripple effect', 'int': 'Wave'},
              {'word': 'Current', 'ipa': '/ˈkʌr.ənt/', 'def': 'A body of water moving in a definite direction.', 'coll': 'ocean current', 'int': 'Flow'}
            ]
          }
        ]
      }
    ];
  }

  void _handleNext() {
    _hapticService.light();
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'topicVocab',
        level: widget.level,
        phase: 'learn',
      );
      if (mounted) {
        try {
          context.pushReplacement(
            '/practice?category=vocabulary&gameType=topicVocab&level=${widget.level}',
          );
        } catch (_) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('topicVocab', level: widget.level);
    final accentColor = theme.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return LearnPhaseScaffold(
        title: 'Topic Vocab Lab',
        gameType: 'topicVocab',
        level: widget.level,
        isActionEnabled: false,
        onComplete: () {},
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            children: [
              ShimmerLoading.rounded(height: 70.h, width: double.infinity, borderRadius: 16),
              SizedBox(height: 16.h),
              ShimmerLoading.rounded(height: 140.h, width: double.infinity, borderRadius: 16),
              SizedBox(height: 16.h),
              ShimmerLoading.rounded(height: 140.h, width: double.infinity, borderRadius: 16),
            ],
          ),
        ),
      );
    }

    final quest = _quests[_currentIndex];
    final isLast = _currentIndex == _quests.length - 1;

    return LearnPhaseScaffold(
      title: 'Topic Vocab Lab',
      gameType: 'topicVocab',
      level: widget.level,
      isActionEnabled: true,
      actionLabel: isLast ? 'Got It! Start Practice' : 'Next Category (${_currentIndex + 1}/${_quests.length})',
      onComplete: _handleNext,
      child: Column(
        children: [
          if (_quests.length > 1)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_quests.length, (idx) {
                  final isActive = idx == _currentIndex;
                  final isDone = idx < _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    width: isActive ? 22.w : 7.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: isActive
                          ? accentColor
                          : (isDone
                              ? accentColor.withValues(alpha: 0.45)
                              : (isDark ? Colors.white24 : Colors.black12)),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  );
                }),
              ),
            ),
          Expanded(
            child: TopicBlueprintTree(
              conceptTitle: quest['conceptTitle'] as String? ?? 'Thematic Clusters',
              topicEmoji: quest['topicEmoji'] as String? ?? '🏷️',
              categories: (quest['categories'] as List<dynamic>?) ?? [],
              contrastInsight: quest['contrastInsight'] as String?,
              accentColor: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
