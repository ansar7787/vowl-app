import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/phases/phase_progress_indicator.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_map_node.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:confetti/confetti.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthBloc mockAuthBloc;
  late AnimationController unlockPathController;
  late AnimationController glowController;
  late ConfettiController confettiController;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget buildNode({
    required UserEntity user,
    required TickerProvider vsync,
  }) {
    unlockPathController = AnimationController(vsync: vsync);
    glowController = AnimationController(vsync: vsync);
    confettiController = ConfettiController(duration: const Duration(seconds: 1));

    when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(user));
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: Scaffold(
            body: SingleChildScrollView(
              child: ModernMapNode(
                index: 0,
                levelNumber: 1,
                totalLevels: 1,
                point: const Offset(187.5, 50),
                points: const [Offset(187.5, 50)],
                rowSpacing: 100,
                unlockedLevels: 1,
                completedLevels: 0,
                isPremium: false,
                justUnlockedLevel: null,
                celebratingLevel: null,
                unlockPathController: unlockPathController,
                glowController: glowController,
                confettiController: confettiController,
                theme: const ThemeResult(
                  primaryColor: Colors.blue,
                  accentColor: Colors.amber,
                  backgroundColors: [Colors.blue, Colors.lightBlue],
                  title: 'Vocabulary',
                  icon: Icons.book,
                  category: GameCategory.vocabulary,
                ),
                isDark: false,
                categoryId: 'vocabulary',
                gameType: 'flashcards',
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('ModernMapNode displays PhaseProgressIndicator when user has phase progress', (tester) async {
    const userWithPhases = UserEntity(
      id: 'test_u',
      email: 'test@vowl.app',
      phaseProgress: {
        'flashcards': {
          '1': {'learn'},
        },
      },
    );

    await tester.pumpWidget(
      TestVSyncWidget(
        builder: (context, vsync) => buildNode(user: userWithPhases, vsync: vsync),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PhaseProgressIndicator), findsOneWidget);
  });
}

class TestVSyncWidget extends StatefulWidget {
  final Widget Function(BuildContext context, TickerProvider vsync) builder;
  const TestVSyncWidget({super.key, required this.builder});

  @override
  State<TestVSyncWidget> createState() => _TestVSyncWidgetState();
}

class _TestVSyncWidgetState extends State<TestVSyncWidget> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, this);
  }
}
