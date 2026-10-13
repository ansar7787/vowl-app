import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/daily_challenges/word_mixer/presentation/pages/word_mixer_screen.dart';
import 'package:vowl/features/daily_challenges/word_snap/presentation/pages/word_snap_screen.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/features/daily_challenges/word_snap/presentation/widgets/word_snap_top_bar.dart';

class MockHapticService extends Mock implements HapticService {}
class MockSoundService extends Mock implements SoundService {}
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHaptic;
  late MockSoundService mockSound;
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    mockHaptic = MockHapticService();
    mockSound = MockSoundService();
    mockAuthBloc = MockAuthBloc();

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user',
          email: 'test@vowl.app',
          displayName: 'Tester',
          currentStreak: 3,
        ),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHaptic);

    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
    di.sl.registerSingleton<SoundService>(mockSound);
  });

  Widget wrapScreen(Widget child) {
    return BlocProvider<AuthBloc>.value(
      value: mockAuthBloc,
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(
          theme: AppTheme.lightTheme,
          home: child,
        ),
      ),
    );
  }

  testWidgets('WordMixerScreen loads puzzle and renders board without crashing', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(wrapScreen(const WordMixerScreen()));
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(WordMixerScreen), findsOneWidget);
    expect(find.byType(GameShimmerLoading), findsNothing);
  });

  testWidgets('WordSnapScreen loads puzzle and renders board without crashing', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(wrapScreen(const WordSnapScreen(level: 1)));
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(WordSnapScreen), findsOneWidget);
    expect(find.byType(WordSnapTopBar), findsOneWidget);
    expect(find.byType(GameShimmerLoading), findsNothing);
  });
}

