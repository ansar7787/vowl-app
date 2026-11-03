import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/home/presentation/widgets/inline_notification_card.dart';

class MockHapticService extends Mock implements HapticService {}

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;
  late MockLocaleService mockLocaleService;

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockHapticService = MockHapticService();
    mockLocaleService = MockLocaleService();

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));
    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer((inv) {
      final fallback = inv.namedArguments[#fallback] as String?;
      final args = inv.namedArguments[#args] as List<String>?;
      if (fallback != null && args != null && args.isNotEmpty) {
        var res = fallback;
        for (final arg in args) {
          res = res.replaceFirst('{}', arg);
        }
        return res;
      }
      return fallback ?? (inv.positionalArguments.first as String);
    });

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    initLocaleServiceReference(mockLocaleService);

    SharedPreferences.setMockInitialValues({});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'checkPermissionStatus') {
          // 0 = PermissionStatus.denied (not granted and not permanently denied)
          return 0;
        }
        if (methodCall.method == 'requestPermissions') {
          return {17: 0};
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      null,
    );
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
  });

  Widget createSubject({
    required int streak,
    ThemeMode themeMode = ThemeMode.dark,
    double width = 393,
    double height = 852,
  }) {
    return ScreenUtilInit(
      designSize: Size(width, height),
      builder: (context, _) => MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: Scaffold(
          body: InlineNotificationCard(streak: streak),
        ),
      ),
    );
  }

  testWidgets(
    'renders short title and subtitle for streak >= 3',
    (tester) async {
      await tester.pumpWidget(createSubject(streak: 14));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Notification card renders when not dismissed
      expect(find.byType(InlineNotificationCard), findsOneWidget);
      expect(find.text("Save your 14-day streak!"), findsOneWidget);
      expect(find.text("A quick alert before midnight so you never lose it"), findsOneWidget);
      expect(find.text('Remind Me'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'renders starter momentum copy for streak = 1 or 2',
    (tester) async {
      await tester.pumpWidget(createSubject(streak: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text("Keep your streak going!"), findsOneWidget);
      expect(find.text("A quick daily reminder to help you hit a 7-day streak"), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'renders quest copy for new learner streak = 0',
    (tester) async {
      await tester.pumpWidget(createSubject(streak: 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text("Start your streak today!"), findsOneWidget);
      expect(find.text("A quick 2-minute reminder so you never miss a day"), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'tapping close icon triggers dismissal and runs collapse animation',
    (tester) async {
      await tester.pumpWidget(createSubject(streak: 14));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => mockHapticService.light()).called(1);

      // Card is dismissed and collapsed away
      expect(find.text("Save your 14-day streak!"), findsNothing);
    },
  );

  testWidgets(
    'does not render when card was dismissed within the 7-day cooldown',
    (tester) async {
      // Set recent dismissal timestamp
      final recentDismissal = DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'notification_card_dismissed_time': recentDismissal,
      });

      await tester.pumpWidget(createSubject(streak: 14));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text("Save your 14-day streak!"), findsNothing);
    },
  );

  testWidgets(
    'renders safely on small 320dp mobile screen without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 568 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createSubject(
          streak: 14,
          width: 320,
          height: 568,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(InlineNotificationCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders cleanly in Light Mode without errors',
    (tester) async {
      await tester.pumpWidget(
        createSubject(
          streak: 14,
          themeMode: ThemeMode.light,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(InlineNotificationCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
