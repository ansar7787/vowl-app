import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_result_dialog.dart';
import 'package:vowl/features/arena/presentation/widgets/arena_score_hud.dart';

void main() {
  group('1v1 Arena Overflow Resistance Verification', () {
    void setupScreen(WidgetTester tester, Size size) {
      tester.view.physicalSize = Size(size.width * 2, size.height * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    Widget buildTestWidget({
      required Widget child,
      Size screenSize = const Size(320, 640),
    }) {
      return ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(size: screenSize),
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets(
      'ArenaScoreHud never overflows with ultra-long user names on small screen',
      (tester) async {
        const size = Size(320, 640);
        setupScreen(tester, size);

        await tester.pumpWidget(
          buildTestWidget(
            screenSize: size,
            child: const ArenaScoreHud(
              myName: 'Sir Christopher Alexander Montgomery III',
              rivalName: 'Grandmaster Elizabeth Catherine Windermere',
              myScore: 9999,
              rivalScore: 8888,
              currentQuestionIndex: 4,
              totalQuestions: 5,
              timeRemaining: 1,
              isDark: true,
              animateTimer: false,
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ArenaResultDialog never overflows with long names and extreme content on small screen',
      (tester) async {
        const size = Size(320, 640);
        setupScreen(tester, size);

        await tester.pumpWidget(
          buildTestWidget(
            screenSize: size,
            child: ArenaResultDialog(
              isWinner: true,
              isSpeedTieBreak: true,
              speedDiffSeconds: 2.45,
              myScore: 450,
              rivalScore: 450,
              myCorrectCount: 5,
              rivalCorrectCount: 5,
              myTotalTimeMs: 7200,
              rivalTotalTimeMs: 9650,
              myName: 'Alexander the Great of Macedon',
              rivalName: 'Emperor Napoleon Bonaparte the Emperor',
              payoutCoins: 50,
              roomCode: 'VOWL-DUEL-999',
              showConfetti: false,
              onRematch: () {},
              onClose: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ArenaResultDialog renders cleanly on standard 390x844 device without overflow',
      (tester) async {
        const size = Size(390, 844);
        setupScreen(tester, size);

        await tester.pumpWidget(
          buildTestWidget(
            screenSize: size,
            child: ArenaResultDialog(
              isWinner: false,
              isSpeedTieBreak: false,
              myScore: 300,
              rivalScore: 420,
              myCorrectCount: 3,
              rivalCorrectCount: 5,
              myTotalTimeMs: 14200,
              rivalTotalTimeMs: 8650,
              myName: 'Lexicon Master',
              rivalName: 'Sophia Chen',
              payoutCoins: 10,
              roomCode: 'VOWL-DUEL-123',
              onRematch: () {},
              onClose: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ArenaResultDialog renders cleanly on large 430x932 Max device without overflow',
      (tester) async {
        const size = Size(430, 932);
        setupScreen(tester, size);

        await tester.pumpWidget(
          buildTestWidget(
            screenSize: size,
            child: ArenaResultDialog(
              isWinner: true,
              isSpeedTieBreak: false,
              myScore: 500,
              rivalScore: 380,
              myCorrectCount: 5,
              rivalCorrectCount: 4,
              myTotalTimeMs: 6500,
              rivalTotalTimeMs: 9100,
              myName: 'Athena Pro',
              rivalName: 'Hermes Speedy',
              payoutCoins: 50,
              roomCode: 'VOWL-DUEL-MAX',
              onRematch: () {},
              onClose: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Arena Question Card and Option Cards never overflow on small 320x640 screen',
      (tester) async {
        const size = Size(320, 640);
        setupScreen(tester, size);

        // Simulates the full battle screen arena card & option buttons
        await tester.pumpWidget(
          buildTestWidget(
            screenSize: size,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ArenaScoreHud(
                      myName: 'Ultra Challenger With A Very Long Name',
                      rivalName: 'Formidable Rival Grandmaster Alexander',
                      myScore: 420,
                      rivalScore: 380,
                      currentQuestionIndex: 2,
                      totalQuestions: 5,
                      timeRemaining: 7,
                      isDark: true,
                      animateTimer: false,
                    ),
                    const SizedBox(height: 16),
                    // Question Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.midnightSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.slate800),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.indigo500.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'PHRASE DUEL • IDIOM',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.indigo500,
                                    ),
                                  ),
                                ),
                              ),
                              const Text(
                                'ROUND 3 OF 5',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'What does "burn the midnight oil" most accurately mean in academic context?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Options List
                    Expanded(
                      child: ListView.separated(
                        itemCount: 4,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final options = [
                            'To work or study late into the night with rigorous focus',
                            'To waste precious natural resources without consideration',
                            'To spark an unintentional heated debate among scholars',
                            'To ignite a ceremonial lamp during nocturnal gatherings',
                          ];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.slate800,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E293B),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    String.fromCharCode(65 + idx),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    options[idx],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Live Explanation Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.slate800),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.lightbulb,
                            size: 15,
                            color: Color(0xFFF59E0B),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '"Burn the midnight oil" originates from historical oil lamps used for reading late into the evening.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
