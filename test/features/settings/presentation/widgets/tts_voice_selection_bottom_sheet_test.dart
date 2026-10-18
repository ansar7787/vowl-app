import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/tts_voice_helper.dart';
import 'package:vowl/features/settings/presentation/widgets/tts_voice_selection_bottom_sheet.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
          call,
        ) async {
          if (call.method == 'getVoices') {
            return <Map<String, String>>[];
          }
          return 1;
        });

    SharedPreferences.setMockInitialValues({});
    if (!di.sl.isRegistered<AppLogger>()) {
      di.sl.registerLazySingleton<AppLogger>(() => const DebugAppLogger());
    }
    if (!di.sl.isRegistered<HapticService>()) {
      di.sl.registerLazySingleton<HapticService>(() => MockHapticService());
    }
    if (!di.sl.isRegistered<TtsService>()) {
      di.sl.registerLazySingleton<TtsService>(() => TtsService());
    }
  });

  Widget buildTestableWidget({
    Size screenSize = const Size(360, 690),
    TtsVoicePreset initialPreset = TtsVoicePreset.clearGuide,
    bool isPremium = true,
  }) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) => MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: TtsVoiceSelectionBottomSheet(
              initialPreset: initialPreset,
              isPremium: isPremium,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'renders all voice options and badges without any render overflow',
    (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Pronunciation Voice'), findsOneWidget);
      expect(find.text('Friendly Teacher'), findsOneWidget);
      expect(find.text('KIDS FAVORITE'), findsOneWidget);
      expect(find.text('Clear Guide'), findsOneWidget);
      expect(find.text('British Accent'), findsOneWidget);
      expect(find.text('Australian Accent'), findsOneWidget);
      expect(find.text('Indian English'), findsOneWidget);
      expect(find.text('Device Default'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Verify no RenderFlex overflow error was triggered
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders correctly on narrow 320px width device without overflow',
    (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(screenSize: const Size(320, 640)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Friendly Teacher'), findsOneWidget);
      expect(find.text('KIDS FAVORITE'), findsOneWidget);
      expect(find.text('Australian Accent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selecting another preset updates active card smoothly', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(initialPreset: TtsVoicePreset.friendlyTeacher),
    );
    await tester.pumpAndSettle();

    // Tap Clear Guide
    await tester.tap(find.text('Clear Guide'));
    await tester.pumpAndSettle();

    // Sheet should still be open
    expect(find.text('Pronunciation Voice'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Verify it was persisted
    final saved = await TtsVoiceHelper.getSavedPreset();
    expect(saved, TtsVoicePreset.clearGuide);
  });

  testWidgets(
    'tapping preview button starts audio wave animation and toggle stops it',
    (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(initialPreset: TtsVoicePreset.friendlyTeacher),
      );
      await tester.pumpAndSettle();

      // Find the preview button
      final previewBtnFinder = find.byTooltip('Listen to voice sample').first;
      expect(previewBtnFinder, findsOneWidget);

      // Tap preview
      await tester.tap(previewBtnFinder);
      await tester.pump();

      // Verify tooltip updated to stop
      expect(find.byTooltip('Stop voice sample'), findsOneWidget);

      // Tap to stop
      await tester.tap(find.byTooltip('Stop voice sample').first);
      await tester.pump();

      expect(find.byTooltip('Listen to voice sample'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'premium user can select British Accent and tap Done to return it',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TtsVoicePreset? selectedResult;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(400, 1100),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    selectedResult = await TtsVoiceSelectionBottomSheet.show(
                      ctx,
                      currentPreset: TtsVoicePreset.friendlyTeacher,
                      isPremium: true,
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Select British Accent
      await tester.tap(find.text('British Accent'));
      await tester.pumpAndSettle();

      // Ensure Done is visible and tap
      await tester.ensureVisible(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Sheet dismissed
      expect(find.text('Pronunciation Voice'), findsNothing);
      expect(selectedResult, TtsVoicePreset.britishAccent);
    },
  );

  testWidgets(
    'free user opening sheet with initial preset set to locked voice sanitizes safely to Clear Guide',
    (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          initialPreset: TtsVoicePreset.britishAccent,
          isPremium: false,
        ),
      );
      await tester.pumpAndSettle();

      // Check lock icons are rendered for locked presets
      expect(find.byIcon(LucideIcons.lock), findsWidgets);

      // Verify that the sheet opens without error and clear guide is rendered
      expect(find.text('Pronunciation Voice'), findsOneWidget);
      expect(find.text('Clear Guide'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
