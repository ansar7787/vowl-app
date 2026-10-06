import re

with open("lib/features/profile/presentation/pages/review_mistakes_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Fix _buildEmptyState
empty_state_correct = """  Widget _buildEmptyState(BuildContext context, bool isDark) {
    Widget w = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_rounded, size: 64.r, color: AppColors.emerald500),
          SizedBox(height: 16.h),
          Text(
            context.tr('profile.no_mistakes_title', fallback: "You're All Caught Up!"),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            context.tr('profile.no_mistakes_subtitle', fallback: 'Your error journal is completely empty.'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
    if (!VowlMotion.shouldReduceMotion(context)) {
      w = w.animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack).fadeIn();
    }
    return w;
  }"""

content = re.sub(r"  Widget _buildEmptyState\(BuildContext context, bool isDark\) \{.*?(?=  Widget _buildShimmerItem)", empty_state_correct + "\n\n", content, flags=re.DOTALL)


# Fix _buildMistakeCard
mistake_card_correct = """  Widget _buildMistakeCard(ErrorJournalEntry entry, int index, bool isDark) {
    Widget card = ScaleButton(
      onTap: () async {
        di.sl<HapticService>().selection();
        
        final category = QuestRegistry.gameToCategory[entry.gameType] ?? 'reading';
        final uri = Uri(
          path: '/game',
          queryParameters: {
            'category': category,
            'subtype': entry.gameType,
            'level': entry.level.toString(),
          },
        );
        
        await context.push(uri.toString());
        
        if (mounted) {
          _loadMistakes();
        }
      },
      child: GlassTile(
        borderRadius: BorderRadius.circular(16.r),
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    entry.gameType.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.indigo500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20.r, color: isDark ? Colors.white54 : Colors.black54),
                  onPressed: () => _dismissMistake(entry.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              entry.question,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 16.h),
            _buildAnswerRow(
              context, 
              Icons.close_rounded, 
              AppColors.red500, 
              context.tr('profile.you_answered', fallback: 'You answered:'), 
              entry.userAnswer,
            ),
            SizedBox(height: 8.h),
            _buildAnswerRow(
              context, 
              Icons.check_rounded, 
              AppColors.emerald500, 
              context.tr('profile.correct_answer', fallback: 'Correct answer:'), 
              entry.correctAnswer,
            ),
          ],
        ),
      ),
    );
    
    if (!VowlMotion.shouldReduceMotion(context)) {
      return card.animate().slideY(
        begin: 0.2, 
        delay: (index.clamp(0, 10) * 50).ms, 
        duration: 300.ms, 
        curve: Curves.easeOutCubic,
      ).fadeIn();
    }
    
    return card;
  }"""

content = re.sub(r"  Widget _buildMistakeCard\(ErrorJournalEntry entry, int index, bool isDark\) \{.*?(?=  Widget _buildAnswerRow)", mistake_card_correct + "\n\n", content, flags=re.DOTALL)

with open("lib/features/profile/presentation/pages/review_mistakes_screen.dart", "w", encoding="utf-8") as f:
    f.write(content)
