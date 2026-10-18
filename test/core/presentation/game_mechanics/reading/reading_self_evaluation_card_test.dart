import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/game_mechanics/reading/reading_self_evaluation_card.dart';
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

  testWidgets('ReadingSelfEvaluationCard reveals answer on tap and shows standardized coin badge', (
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
            home: Scaffold(
              body: ReadingSelfEvaluationCard(
                correctAnswer: 'Paris is the capital',
                explanation: 'Geography context',
                primaryColor: Colors.blue,
                bonusCoins: 5,
                onEvaluated: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Initially shows reveal button
    expect(find.text('TAP TO REVEAL ANSWER'), findsOneWidget);

    // Tap to reveal
    await tester.tap(find.text('TAP TO REVEAL ANSWER'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Shows correct answer and standardized coin badge
    expect(find.text('Paris is the capital'), findsOneWidget);
    expect(find.text('+5 coins'), findsOneWidget);
    expect(find.text('NAILED IT'), findsOneWidget);
    expect(find.text('MISSED IT'), findsOneWidget);
  });
}

