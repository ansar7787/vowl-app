import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/games/vowl_peeking_companion.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

Widget _buildTestableWidget({
  required Widget child,
  required AuthBloc authBloc,
}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (context, _) => BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        UserEntity(
          id: '1',
          email: 'test@vowl.com',
          vowlMascot: 'vowl_prime',
        ),
      ),
    );
  });

  group('VowlPeekingCompanion Widget Tests', () {
    testWidgets('Renders speech bubble initially and collapses after autoDismissDuration',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestableWidget(
          authBloc: mockAuthBloc,
          child: const VowlPeekingCompanion(
            message: 'Focus and win!',
            mascotState: VowlMascotState.happy,
            mascotId: 'vowl_prime',
            category: 'grammar',
            autoDismissDuration: Duration(seconds: 3),
          ),
        ),
      );

      // Initially, message text is present
      expect(find.text('Focus and win!'), findsOneWidget);

      // Fast forward 3.5 seconds
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 350));

      // After dismiss duration, the bubble widget is collapsed (SizedBox.shrink)
      expect(find.text('Focus and win!'), findsNothing);

      // Tap mascot to revive speech bubble
      await tester.tap(find.byType(VowlPeekingCompanion));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Bubble is visible again
      expect(find.text('Focus and win!'), findsOneWidget);
    });
  });
}
