import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/game_skip_bypass_button.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(
      () => mockAuthBloc.state,
    ).thenReturn(const AuthState.unauthenticated());
  });

  testWidgets(
    'GameSkipBypassButton renders SKIP label and responds to attempts',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final isSubmitting = ValueNotifier<bool>(false);
      final attempts = ValueNotifier<int>(0);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: MaterialApp(
              home: Scaffold(
                body: GameSkipBypassButton(
                  subtitleColor: Colors.grey,
                  isSubmitting: isSubmitting,
                  attempts: attempts,
                  maxAttempts: 3,
                  onConfirmed: () {},
                  onSkipped: () {},
                  onSubmittingChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SKIP'), findsOneWidget);

      // When attempts reach maxAttempts (3), label changes to CONTINUE
      attempts.value = 3;
      await tester.pumpAndSettle();

      expect(find.text('CONTINUE'), findsOneWidget);
    },
  );
}
