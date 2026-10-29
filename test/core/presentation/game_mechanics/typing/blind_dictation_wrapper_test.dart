import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/blind_dictation_wrapper.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState> implements EconomyBloc {}
class MockHapticService extends Mock implements HapticService {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    when(() => mockAuthBloc.state).thenReturn(const AuthState.unauthenticated());
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

  testWidgets('BlindDictationWrapper renders natural header, badge, and submit button', (
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
        builder: (context, _) => MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Stack(
                children: [
                  BlindDictationWrapper(
                    expectedText: 'listen to this audio',
                    primaryColor: Colors.blue,
                    onConfirmed: () {},
                    onSkipped: () {},
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

    // Verify non-buzzword header and submit button, no coin badge
    expect(find.text('LISTEN & TYPE'), findsOneWidget);
    expect(find.text('+5 coins'), findsNothing);
    expect(find.text('SUBMIT'), findsOneWidget);
  });

  testWidgets('BlindDictationWrapper with isPositioned: false renders as card with rounded corners and no handle bar', (
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
        builder: (context, _) => MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: BlindDictationWrapper(
                  expectedText: 'listen to this audio',
                  primaryColor: Colors.blue,
                  isPositioned: false,
                  onConfirmed: () {},
                  onSkipped: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('LISTEN & TYPE'), findsOneWidget);
    expect(find.text('SUBMIT'), findsOneWidget);

    // Verify container has all-around rounded corners (card)
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(BlindDictationWrapper),
        matching: find.byType(Container),
      ).first,
    );
    final boxDecoration = container.decoration as BoxDecoration;
    expect(boxDecoration.borderRadius, BorderRadius.circular(24.r));
  });

  testWidgets('BlindDictationWrapper text write field has 4-side curves, anti-alias clipping, and visible border', (
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
        builder: (context, _) => MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: BlindDictationWrapper(
                  expectedText: 'apple',
                  primaryColor: Colors.deepPurple,
                  isPositioned: false,
                  onConfirmed: () {},
                  onSkipped: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Find TextField and its parent input Container
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    final inputContainerFinder = find.ancestor(
      of: textField,
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.clipBehavior == Clip.antiAlias,
      ),
    );
    expect(inputContainerFinder, findsOneWidget);

    final inputContainer = tester.widget<Container>(inputContainerFinder);
    final dec = inputContainer.decoration as BoxDecoration;
    // Verify 4-side curve
    expect(dec.borderRadius, BorderRadius.circular(16.r));
    // Verify anti-alias clip
    expect(inputContainer.clipBehavior, Clip.antiAlias);
    // Verify visible border styling
    expect(dec.border, isNotNull);
    final border = dec.border as Border;
    expect(border.top.width, 1.5.w);
    expect(border.bottom.width, 1.5.w);
    expect(border.left.width, 1.5.w);
    expect(border.right.width, 1.5.w);
  });
}

