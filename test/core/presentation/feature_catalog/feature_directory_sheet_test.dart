import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/feature_catalog/beginner_discovery_card.dart';
import 'package:vowl/core/presentation/feature_catalog/feature_directory_bottom_sheet.dart';
import 'package:vowl/core/presentation/feature_catalog/first_time_welcome_showcase.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class MockHapticService implements HapticService {
  @override
  bool isHapticsEnabled = true;
  @override
  Future<void> error() async {}
  @override
  Future<void> heavy() async {}
  @override
  Future<void> light() async {}
  @override
  Future<void> rhythmicTick() async {}
  @override
  Future<void> selection() async {}
  @override
  Future<void> success() async {}
  @override
  Future<void> warning() async {}
}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockEconomyBloc mockEconomyBloc;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    if (!di.sl.isRegistered<HapticService>()) {
      di.sl.registerLazySingleton<HapticService>(() => MockHapticService());
    }
    mockEconomyBloc = MockEconomyBloc();
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
  });

  const testUser = UserEntity(
    id: 'user_123',
    email: 'test@vowl.app',
    completedLevels: {},
    totalExp: 100,
  );

  Widget wrapWidget(
    Widget child, {
    Size size = const Size(390, 844),
    bool scrollable = false,
  }) {
    return ScreenUtilInit(
      designSize: size,
      builder: (context, _) => MaterialApp(
        home: BlocProvider<EconomyBloc>.value(
          value: mockEconomyBloc,
          child: Scaffold(
            body: scrollable ? SingleChildScrollView(child: child) : child,
          ),
        ),
      ),
    );
  }

  group('FeatureDirectoryBottomSheet', () {
    testWidgets('renders search, category filter, and feature cards without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapWidget(const FeatureDirectoryBottomSheet()));
      await tester.pumpAndSettle();

      expect(find.text('Explore All Features'), findsOneWidget);
      expect(find.text('100+ Games Hub'), findsOneWidget);
      expect(find.text('Speaking & Speech Recognition'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Search for specific feature
      await tester.enterText(find.byType(TextField), 'photo');
      await tester.pumpAndSettle();

      expect(find.text('Photo Vocab'), findsOneWidget);
      expect(find.text('100+ Games Hub'), findsNothing);
      expect(tester.takeException(), isNull);

      // Search for offline translator
      await tester.enterText(find.byType(TextField), 'offline');
      await tester.pumpAndSettle();

      expect(find.text('50+ Languages Offline Translator'), findsOneWidget);
      expect(find.text('Photo Vocab'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on narrow 320px device without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrapWidget(
          const FeatureDirectoryBottomSheet(),
          size: const Size(320, 640),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Explore All Features'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('BeginnerDiscoveryCard', () {
    testWidgets('displays quests, progress bar, and dismisses on close tap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrapWidget(
          const BeginnerDiscoveryCard(user: testUser),
          scrollable: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Beginner Discovery Quests'), findsOneWidget);
      expect(find.text('Complete 1 Lesson'), findsOneWidget);
      expect(find.text('Try Camera AI in Photo Vocab'), findsOneWidget);
      expect(find.text('Visit Buddy Boutique & Pet'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tap dismiss
      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pumpAndSettle();

      // Card disappears
      expect(find.text('Beginner Discovery Quests'), findsNothing);
    });
  });

  group('FirstTimeWelcomeShowcase', () {
    testWidgets('renders showcase slides and can skip cleanly', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrapWidget(const FirstTimeWelcomeShowcase()),
      );
      await tester.pumpAndSettle();

      expect(find.text('100+ Games Across 9 Pillars'), findsOneWidget);
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tap Next / Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('AI Vision & 50+ Languages'), findsOneWidget);
      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

