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

    testWidgets('Free user with 0 hints renders videocam icon and +1 text for rewarded ad', (tester) async {
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

      expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
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
  });
}
