import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user',
          email: 'test@vowl.app',
          displayName: 'Hero',
          isEmailVerified: true,
        ),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: MaterialApp(
          home: child,
        ),
      ),
    );
  }

  group('PracticePhaseScaffold', () {
    testWidgets('renders title, progress, practice badge and triggers onComplete', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          PracticePhaseScaffold(
            title: 'Word Gym',
            gameType: 'flashcards',
            level: 1,
            currentExerciseIndex: 0,
            totalExercises: 3,
            onComplete: () => completed = true,
            child: const Text('Practice Question Body'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Word Gym'), findsOneWidget);
      expect(find.text('PRACTICE PHASE • LEVEL 1 • A2'), findsOneWidget);
      expect(find.text('Practice Question Body'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(completed, isTrue);
    });

    testWidgets('tapping close icon triggers exit confirmation dialog when onExit is null', (tester) async {
      tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(
          PracticePhaseScaffold(
            title: 'Word Gym',
            gameType: 'flashcards',
            level: 1,
            currentExerciseIndex: 0,
            totalExercises: 3,
            onComplete: () {},
            child: const Text('Question Body'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final closeBtn = find.byIcon(Icons.close_rounded);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('QUIT PRACTICE?'), findsOneWidget);
      expect(find.text('KEEP PRACTICING'), findsOneWidget);
      expect(find.text('EXIT'), findsOneWidget);

      await tester.tap(find.text('KEEP PRACTICING'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('QUIT PRACTICE?'), findsNothing);
    });

    testWidgets('tapping close icon calls onExit callback when provided', (tester) async {
      bool exitCalled = false;
      await tester.pumpWidget(
        buildTestableWidget(
          PracticePhaseScaffold(
            title: 'Word Gym',
            gameType: 'flashcards',
            level: 1,
            currentExerciseIndex: 0,
            totalExercises: 3,
            onExit: () => exitCalled = true,
            onComplete: () {},
            child: const Text('Question Body'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(exitCalled, isTrue);
      expect(find.text('QUIT GAME?'), findsNothing);
    });
  });
}
