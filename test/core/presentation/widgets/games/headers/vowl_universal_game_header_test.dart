import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/games/headers/vowl_universal_game_header.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockEconomyBloc extends Mock implements EconomyBloc {}

Widget _buildTestableWidget({
  required Widget child,
  required AuthBloc authBloc,
  required EconomyBloc economyBloc,
  Brightness brightness = Brightness.light,
}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (context, _) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<EconomyBloc>.value(value: economyBloc),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: child,
          ),
        ),
      );
    },
  );
}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();

    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
  });

  group('VowlUniversalGameHeader Widget Tests', () {
    testWidgets('renders tactile pause button with dual rounded bars and invokes callback', (tester) async {
      bool pauseCalled = false;

      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          UserEntity(id: '1', email: 'test@vowl.com', hintCount: 2),
        ),
      );

      await tester.pumpWidget(
        _buildTestableWidget(
          authBloc: mockAuthBloc,
          economyBloc: mockEconomyBloc,
          child: VowlUniversalGameHeader(
            level: 5,
            category: 'grammar',
            progress: 0.5,
            lives: 3,
            onPause: () => pauseCalled = true,
            onBriefing: () {},
            onHint: () {},
          ),
        ),
      );

      // Verify level text
      expect(find.text('LEVEL 5'), findsOneWidget);

      // Verify tactile pause button semantics
      final pauseButton = find.bySemanticsLabel('Pause Game');
      expect(pauseButton, findsOneWidget);

      await tester.tap(pauseButton);
      await tester.pump();
      expect(pauseCalled, isTrue);
    });

    testWidgets('Free user with hints renders lightbulb and hint count', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          UserEntity(id: '1', email: 'test@vowl.com', hintCount: 2, isPremium: false),
        ),
      );

      await tester.pumpWidget(
        _buildTestableWidget(
          authBloc: mockAuthBloc,
          economyBloc: mockEconomyBloc,
          child: VowlUniversalGameHeader(
            level: 1,
            category: 'vocabulary',
            onPause: () {},
            onBriefing: () {},
            onHint: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('Free user with 0 hints renders clean video collection icon for rewarded ad without duplicate play badges', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          UserEntity(id: '1', email: 'test@vowl.com', hintCount: 0, isPremium: false),
        ),
      );

      await tester.pumpWidget(
        _buildTestableWidget(
          authBloc: mockAuthBloc,
          economyBloc: mockEconomyBloc,
          child: VowlUniversalGameHeader(
            level: 1,
            category: 'grammar',
            onPause: () {},
            onBriefing: () {},
            onHint: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.video_collection_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.text('+1'), findsNothing);
    });

    testWidgets('Premium user renders lightbulb without count label (unlimited)', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          UserEntity(id: '1', email: 'test@vowl.com', hintCount: 0, isPremium: true),
        ),
      );

      await tester.pumpWidget(
        _buildTestableWidget(
          authBloc: mockAuthBloc,
          economyBloc: mockEconomyBloc,
          child: VowlUniversalGameHeader(
            level: 1,
            category: 'reading',
            onPause: () {},
            onBriefing: () {},
            onHint: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);
      // No count or +1 label should be visible for premium
      expect(find.text('+1'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('Revealed/used hint renders psychology icon without counter', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          UserEntity(id: '1', email: 'test@vowl.com', hintCount: 3, isPremium: false),
        ),
      );

      await tester.pumpWidget(
        _buildTestableWidget(
          authBloc: mockAuthBloc,
          economyBloc: mockEconomyBloc,
          child: VowlUniversalGameHeader(
            level: 1,
            category: 'grammar',
            isHintUsedOnCurrentQuest: true,
            onPause: () {},
            onBriefing: () {},
            onHint: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.psychology_outlined), findsOneWidget);
      expect(find.text('3'), findsNothing);
    });

    testWidgets('showBriefing is false by default, maintaining clean 4-pill header', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          UserEntity(id: '1', email: 'test@vowl.com', hintCount: 1),
        ),
      );

      await tester.pumpWidget(
        _buildTestableWidget(
          authBloc: mockAuthBloc,
          economyBloc: mockEconomyBloc,
          child: VowlUniversalGameHeader(
            level: 1,
            category: 'grammar',
            onPause: () {},
            onHint: () {},
          ),
        ),
      );

      // Briefing icon should NOT be in the top row by default
      expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
      // Top row maintains Pause, Level, Hearts, Hint
      expect(find.bySemanticsLabel('Pause Game'), findsOneWidget);
      expect(find.text('LEVEL 1'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);
    });

    testWidgets('renders briefing tile when showBriefing is true', (tester) async {
      bool briefingCalled = false;
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          UserEntity(id: '1', email: 'test@vowl.com', hintCount: 1),
        ),
      );

      await tester.pumpWidget(
        _buildTestableWidget(
          authBloc: mockAuthBloc,
          economyBloc: mockEconomyBloc,
          child: VowlUniversalGameHeader(
            level: 1,
            category: 'grammar',
            showBriefing: true,
            onBriefing: () => briefingCalled = true,
            onPause: () {},
            onHint: () {},
          ),
        ),
      );

      final briefingBtn = find.byIcon(Icons.info_outline_rounded);
      expect(briefingBtn, findsOneWidget);

      await tester.tap(briefingBtn);
      await tester.pump();
      expect(briefingCalled, isTrue);
    });
  });
}
