import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:audioplayers/audioplayers.dart';

class MistakesPracticeScreen extends StatefulWidget {
  const MistakesPracticeScreen({super.key});

  @override
  State<MistakesPracticeScreen> createState() => _MistakesPracticeScreenState();
}

class _MistakesPracticeScreenState extends State<MistakesPracticeScreen> {
  bool _isLoading = true;
  List<ErrorJournalEntry> _entries = [];
  int _currentIndex = 0;
  late String _userId;
  bool _isAnswered = false;
  bool _isCorrect = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadPracticeSession();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadPracticeSession() async {
    final authState = context.read<AuthBloc>().state;
    _userId = authState.user?.id ?? 'local';

    final allEntries = await ErrorJournalCollector.fetch(
      userId: _userId,
      limit: 100, // Fetch pool
    );
    
    // Grab up to 10 random entries for the session
    allEntries.shuffle();
    final sessionEntries = allEntries.take(10).toList();

    if (mounted) {
      setState(() {
        _entries = sessionEntries;
        _isLoading = false;
      });
    }
  }

  void _submitAnswer(bool isCorrect) {
    if (_isAnswered) return;
    
    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      di.sl<HapticService>().success();
      // Safe play sound
      _audioPlayer.play(AssetSource('sounds/correct_chime.mp3')).catchError((_) {});
      
      // Auto dismiss from journal since they got it right!
      ErrorJournalCollector.dismiss(
        userId: _userId, 
        entryId: _entries[_currentIndex].id
      );
    } else {
      di.sl<HapticService>().error();
      _audioPlayer.play(AssetSource('sounds/wrong_buzz.mp3')).catchError((_) {});
    }
  }

  void _nextCard() {
    if (_currentIndex < _entries.length - 1) {
      setState(() {
        _currentIndex++;
        _isAnswered = false;
        _isCorrect = false;
      });
    } else {
      // Session Complete
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          const MeshGradientBackground(showLetters: false),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : _entries.isEmpty 
                          ? _buildEmptyState(context, isDark)
                          : _buildFlashcard(context, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black),
            onPressed: () => context.pop(),
          ),
          if (!_isLoading && _entries.isNotEmpty)
            Text(
              '${_currentIndex + 1} / ${_entries.length}',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          SizedBox(width: 48.w), // Balance spacer
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 80.r, color: AppColors.emerald500),
          SizedBox(height: 24.h),
          Text(
            context.tr('profile.practice_empty', fallback: "No Mistakes to Practice!"),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcard(BuildContext context, bool isDark) {
    final entry = _entries[_currentIndex];

    // Generate 2 options: their old wrong answer, and the correct one.
    // Shuffle them so they don't know which is which.
    final options = [entry.userAnswer, entry.correctAnswer];
    // Use the ID as a random seed so the shuffle is consistent for this specific card
    // but random across cards.
    final random = Random(entry.id.hashCode);
    options.shuffle(random);

    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.indigo500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              entry.gameType.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.indigo500,
                letterSpacing: 1,
              ),
            ),
          ),
          SizedBox(height: 32.h),
          GlassTile(
            borderRadius: BorderRadius.circular(24.r),
            padding: EdgeInsets.all(32.r),
            child: Text(
              entry.question,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          SizedBox(height: 48.h),
          ...options.map((option) => Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: _buildOptionButton(option, option == entry.correctAnswer, isDark),
          )),
          
          if (_isAnswered) ...[
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _nextCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo500,
                minimumSize: Size(double.infinity, 56.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                _currentIndex == _entries.length - 1 ? 'FINISH' : 'NEXT',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildOptionButton(String text, bool isCorrectOption, bool isDark) {
    Color bgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
    Color borderColor = Colors.transparent;

    if (_isAnswered) {
      if (isCorrectOption) {
        bgColor = AppColors.emerald500.withValues(alpha: 0.1);
        borderColor = AppColors.emerald500;
      } else {
        bgColor = AppColors.red500.withValues(alpha: 0.1);
        borderColor = AppColors.red500.withValues(alpha: 0.5);
      }
    }

    return ScaleButton(
      onTap: () {
        if (!_isAnswered) {
          _submitAnswer(isCorrectOption);
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
