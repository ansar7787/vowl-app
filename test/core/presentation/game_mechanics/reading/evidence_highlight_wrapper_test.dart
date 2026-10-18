import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/game_mechanics/reading/evidence_highlight_wrapper.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState> implements EconomyBloc {}
class MockHapticService extends Mock implements HapticService {}

void main() {
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;

  setUp(() {
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);
  });

  tearDown(() {
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
  });

  testWidgets('EvidenceHighlightWrapper renders natural instruction and passage words', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => BlocProvider<EconomyBloc>.value(
          value: mockEconomyBloc,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Stack(
                children: [
                  EvidenceHighlightWrapper(
                    passage: 'The cat slept soundly by the warm fire.',
                    evidenceWords: const ['warm', 'fire'],
                    primaryColor: Colors.amber,
                    bonusCoins: 5,
                    onCorrectHighlight: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify natural non-buzzword instruction text and coins badge
    expect(find.text('FIND THE KEY WORDS'), findsOneWidget);
    expect(find.text('Tap the word(s) that support the answer'), findsOneWidget);
    expect(find.text('+5 coins'), findsOneWidget);
  });
}

