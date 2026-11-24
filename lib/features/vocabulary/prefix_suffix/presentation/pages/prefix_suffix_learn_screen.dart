import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_discovery_card.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_tumbler_cylinder.dart';

/// Learn Phase Screen for Prefix & Suffix: "Affix Tumbler Sandbox".
///
/// Features:
/// - 3D mechanical cylinder wheel to dynamically rotate and bond affixes to roots.
/// - Live discovery card presenting the morphological synthesis formula, definition, and context.
/// - Native TTS audio audition for natural pronunciation.
class PrefixSuffixLearnScreen extends StatefulWidget {
  final int level;

  const PrefixSuffixLearnScreen({super.key, required this.level});

  @override
  State<PrefixSuffixLearnScreen> createState() =>
      _PrefixSuffixLearnScreenState();
}

class _PrefixSuffixLearnScreenState extends State<PrefixSuffixLearnScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _rawQuests = [];
  bool _isLoading = true;
  int _selectedDialIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  int get _batchStart => ((widget.level - 1) ~/ 10) * 10 + 1;
  int get _batchEnd => _batchStart + 9;

  Future<void> _loadCurriculum() async {
    final batchFile =
        'assets/curriculum/vocabulary/prefixSuffix_learn_${_batchStart}_$_batchEnd.json';
    try {
      final jsonString = await rootBundle.loadString(batchFile);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final quests = (data['quests'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final filtered = quests
          .where((q) => (q['level'] as int? ?? widget.level) == widget.level)
          .toList();

      if (mounted) {
        setState(() {
          _rawQuests = filtered.isNotEmpty ? filtered : _buildFallbackQuests();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _rawQuests = _buildFallbackQuests();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildFallbackQuests() {
    return [
      {
        'id': 'VOC_PS_L${widget.level}_LEARN_Q1',
        'level': widget.level,
        'rootWord': 'VIEW',
        'rootMeaning': 'To look at or inspect',
        'affix': 'PRE-',
        'affixType': 'prefix',
        'affixMeaning': 'Before / In advance',
        'combinedWord': 'PREVIEW',
        'definition': 'An early viewing before public release',
        'context': 'We watched the movie preview before the film began.',
        'dialCombinations': [
          {
            'prefix': 'PRE-',
            'suffix': '',
            'combinedWord': 'PREVIEW',
            'affixMeaning': 'Before / In advance',
            'definition': 'An early viewing before public release',
            'context': 'We watched the movie preview before the film began.',
          },
          {
            'prefix': 'RE-',
            'suffix': '',
            'combinedWord': 'REVIEW',
            'affixMeaning': 'Again / Back',
            'definition': 'To inspect or assess once more',
            'context': 'The critic wrote a detailed review of the show.',
          },
        ],
      },
    ];
  }

  void _speakWord(String text) {
    if (text.trim().isNotEmpty && di.sl.isRegistered<TtsService>()) {
      di.sl<TtsService>().speak(text.trim());
    }
  }

  void _completePhase() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'prefixSuffix',
      level: widget.level,
      phase: 'learn',
    );
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ShimmerLoading.rounded(
              width: double.infinity,
              height: 380.h,
              borderRadius: 20,
            ),
          ),
        ),
      );
    }

    final questData = _rawQuests[_currentIndex];
    final rootWord = questData['rootWord'] as String? ?? 'WORD';
    final rawCombinations =
        (questData['dialCombinations'] as List<dynamic>?) ?? [];

    final combinations = rawCombinations.isNotEmpty
        ? rawCombinations.cast<Map<String, dynamic>>()
        : [
            {
              'prefix': questData['affix'] as String? ?? 'PRE-',
              'suffix': '',
              'combinedWord': questData['combinedWord'] as String? ?? 'PREVIEW',
              'affixMeaning':
                  questData['affixMeaning'] as String? ?? 'In advance',
              'definition': questData['definition'] as String? ?? '',
              'context': questData['context'] as String? ?? '',
            },
          ];

    final safeIndex = _selectedDialIndex.clamp(0, combinations.length - 1);
    final activeComb = combinations[safeIndex];
    final affixText = (activeComb['prefix'] as String? ?? '').isNotEmpty
        ? activeComb['prefix'] as String
        : (activeComb['suffix'] as String? ?? '');
    final affixType = (activeComb['prefix'] as String? ?? '').isNotEmpty
        ? 'prefix'
        : 'suffix';
    final combinedWord =
        activeComb['combinedWord'] as String? ??
        questData['combinedWord'] ??
        '';
    final dialItems = combinations.map((c) {
      final p = c['prefix'] as String? ?? '';
      return p.isNotEmpty ? p : (c['suffix'] as String? ?? '');
    }).toList();

    return LearnPhaseScaffold(
      title: 'Prefix & Suffix Studio',
      gameType: 'prefixSuffix',
      level: widget.level,
      actionLabel: _currentIndex < _rawQuests.length - 1
          ? 'Next Word'
          : 'Continue',
      onPrevious: _currentIndex > 0
          ? () {
              setState(() {
                _currentIndex--;
                _selectedDialIndex = 0;
              });
            }
          : null,
      onComplete: () {
        if (_currentIndex < _rawQuests.length - 1) {
          setState(() {
            _currentIndex++;
            _selectedDialIndex = 0;
          });
        } else {
          _completePhase();
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          children: [
            // Mechanical Tumbler Cylinder
            PrefixSuffixTumblerCylinder(
              key: ValueKey('tumbler_${_currentIndex}_${widget.level}'),
              items: dialItems,
              initialIndex: safeIndex,
              title: affixType == 'prefix' ? 'Choose Prefix' : 'Choose Suffix',
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedDialIndex = index;
                });
              },
            ),
            SizedBox(height: 16.h),

            // Live Discovery Card
            PrefixSuffixDiscoveryCard(
              combinedWord: combinedWord,
              rootWord: rootWord,
              affix: affixText,
              affixType: affixType,
              affixMeaning: activeComb['affixMeaning'] as String? ?? '',
              definition: activeComb['definition'] as String? ?? '',
              contextSentence: activeComb['context'] as String? ?? '',
              onPlayTts: () => _speakWord(combinedWord),
              onPlayRootTts: () => _speakWord(rootWord),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
