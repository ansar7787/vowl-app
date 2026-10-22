import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/widgets/speak_opposite_header.dart';

void main() {
  Widget buildTestWidget({
    String? instruction,
    Color primaryColor = Colors.teal,
    ThemeMode themeMode = ThemeMode.dark,
    Size size = const Size(390, 844),
  }) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) => MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: Scaffold(
          body: Center(
            child: SpeakOppositeHeader(
              primaryColor: primaryColor,
              instruction: instruction,
            ),
          ),
        ),
      ),
    );
  }

  group('SpeakOppositeHeader Widget Tests', () {
    testWidgets('renders badge and instruction text with correct keys',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          instruction: 'Speak the opposite of the highlighted word.',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('speak_opposite_header')), findsOneWidget);
      expect(find.byKey(const Key('speak_opposite_badge')), findsOneWidget);
      expect(find.byKey(const Key('speak_opposite_badge_text')), findsOneWidget);
      expect(find.text('OPPOSITE CHALLENGE'), findsOneWidget);
      expect(
        find.byKey(const Key('speak_opposite_instruction_text')),
        findsOneWidget,
      );
      expect(
        find.text('Speak the opposite of the highlighted word.'),
        findsOneWidget,
      );
    });

    testWidgets('instruction text has center alignment', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          instruction: 'Say the opposite word aloud when you are ready.',
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(
        find.byKey(const Key('speak_opposite_instruction_text')),
      );
      expect(textWidget.textAlign, TextAlign.center);
    });

    testWidgets('falls back to default clean instruction when null or empty',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(instruction: null));
      await tester.pumpAndSettle();

      expect(
        find.text('Speak the opposite of the given word.'),
        findsOneWidget,
      );

      await tester.pumpWidget(buildTestWidget(instruction: '   '));
      await tester.pumpAndSettle();

      expect(
        find.text('Speak the opposite of the given word.'),
        findsOneWidget,
      );
    });

    testWidgets('renders swap_horiz_rounded icon inside badge', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
    });

    testWidgets('renders in light and dark mode without overflow',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          instruction:
              'A very long instruction sentence intended to simulate wrapping to a second or third line to verify layout integrity.',
          themeMode: ThemeMode.light,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        buildTestWidget(
          instruction:
              'A very long instruction sentence intended to simulate wrapping to a second or third line to verify layout integrity.',
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
