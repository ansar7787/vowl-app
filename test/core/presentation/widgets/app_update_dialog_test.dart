import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/presentation/widgets/app_update_dialog.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_update_service.dart';

class MockAppUpdateService implements AppUpdateService {
  bool launchStoreCalled = false;
  String? recordedDismissalVersion;

  @override
  Future<AppUpdateInfo> checkForUpdate({bool ignoreFrequencyCap = false}) async {
    return const AppUpdateInfo(
      type: AppUpdateType.flexible,
      currentVersion: '1.0.0',
      latestVersion: '1.0.1',
      minVersion: '1.0.0',
      releaseNotes: '• Polish',
      storeUrl: '',
    );
  }

  @override
  Future<bool> launchStore({String? customUrl}) async {
    launchStoreCalled = true;
    return true;
  }

  @override
  Future<void> recordDismissal(String version) async {
    recordedDismissalVersion = version;
  }
}

void main() {
  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Widget createTestWidget({
    required AppUpdateInfo info,
    required AppUpdateService service,
  }) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(
        home: Scaffold(
          body: AppUpdateDialog(
            updateInfo: info,
            updateService: service,
          ),
        ),
      ),
    );
  }

  group('AppUpdateDialog Widget Tests', () {
    testWidgets('renders flexible update with Update Now and Maybe Later buttons', (tester) async {
      final mockService = MockAppUpdateService();
      const info = AppUpdateInfo(
        type: AppUpdateType.flexible,
        currentVersion: '1.0.0',
        latestVersion: '1.0.5',
        minVersion: '1.0.0',
        releaseNotes: '• Better animations\n• Rank stability',
        storeUrl: '',
      );

      await tester.pumpWidget(createTestWidget(info: info, service: mockService));
      await tester.pumpAndSettle();

      expect(find.text('New Version Available!'), findsOneWidget);
      expect(find.text('v1.0.0  →  v1.0.5'), findsOneWidget);
      expect(find.text('• Better animations\n• Rank stability'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
      expect(find.text('Maybe Later'), findsOneWidget);

      // Tap Maybe Later
      await tester.tap(find.text('Maybe Later'));
      await tester.pumpAndSettle();
      expect(mockService.recordedDismissalVersion, '1.0.5');
    });

    testWidgets('renders forced update without Maybe Later button', (tester) async {
      final mockService = MockAppUpdateService();
      const info = AppUpdateInfo(
        type: AppUpdateType.force,
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        minVersion: '2.0.0',
        releaseNotes: 'Critical security update',
        storeUrl: '',
      );

      await tester.pumpWidget(createTestWidget(info: info, service: mockService));
      await tester.pumpAndSettle();

      expect(find.text('Update Required'), findsOneWidget);
      expect(find.text('v1.0.0  →  v2.0.0'), findsOneWidget);
      expect(find.text('Critical security update'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
      expect(find.text('Maybe Later'), findsNothing);

      // Tap Update Now
      await tester.tap(find.text('Update Now'));
      await tester.pumpAndSettle();
      expect(mockService.launchStoreCalled, isTrue);
    });

    testWidgets('renders default release notes when releaseNotes is empty', (tester) async {
      final mockService = MockAppUpdateService();
      const info = AppUpdateInfo(
        type: AppUpdateType.flexible,
        currentVersion: '1.0.0',
        latestVersion: '1.0.2',
        minVersion: '1.0.0',
        releaseNotes: '',
        storeUrl: '',
      );

      await tester.pumpWidget(createTestWidget(info: info, service: mockService));
      await tester.pumpAndSettle();

      expect(find.textContaining('Performance enhancements'), findsOneWidget);
    });
  });
}

