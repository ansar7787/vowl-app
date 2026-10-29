import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockLocaleService mockLocaleService;

  setUp(() {
    CustomSnackBar.resetDebounce();
    mockLocaleService = MockLocaleService();
    when(
      () => mockLocaleService.tr(
        any(),
        args: any(named: 'args'),
        fallback: any(named: 'fallback'),
      ),
    ).thenAnswer((inv) {
      final key = inv.positionalArguments[0] as String;
      final fallback = inv.namedArguments[#fallback] as String?;
      return fallback ?? key;
    });
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    initLocaleServiceReference(mockLocaleService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
  });

  tearDown(() {
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
  });

  testWidgets(
    'CustomSnackBar shows message and dismisses when close icon is tapped',
    (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => Center(
                  child: ElevatedButton(
                    onPressed: () {
                      CustomSnackBar.show(
                        context: ctx,
                        message: 'Test notification message',
                        type: CustomSnackBarType.success,
                      );
                    },
                    child: const Text('Show'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap show button
      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Test notification message'), findsOneWidget);
      final closeButtonFinder = find.byIcon(Icons.close_rounded);
      expect(closeButtonFinder, findsOneWidget);

      // Tap dismiss button
      await tester.tap(closeButtonFinder);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Test notification message'), findsNothing);
    },
  );

  testWidgets('CustomSnackBar dismiss works even when caller context is popped', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (rootContext) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Open a dialog, show snackbar using dialog's context, then immediately pop dialog
                    showDialog(
                      context: rootContext,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('Dialog'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              CustomSnackBar.show(
                                context: dialogCtx,
                                message: 'Ephemeral dialog alert',
                                type: CustomSnackBarType.info,
                              );
                              Navigator.of(dialogCtx).pop();
                            },
                            child: const Text('Trigger & Pop'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trigger & Pop'));
    await tester.pumpAndSettle();

    // Dialog is gone, snackbar remains visible
    expect(find.text('Dialog'), findsNothing);
    expect(find.text('Ephemeral dialog alert'), findsOneWidget);

    // Tap dismiss on snackbar
    final closeButton = find.byIcon(Icons.close_rounded);
    expect(closeButton, findsOneWidget);

    await tester.tap(closeButton);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Ephemeral dialog alert'), findsNothing);
  });

  testWidgets('CustomSnackBar deduplicates identical rapid calls', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Trigger twice simultaneously
                    CustomSnackBar.show(
                      context: ctx,
                      message: 'Duplicate alert',
                      type: CustomSnackBarType.success,
                    );
                    CustomSnackBar.show(
                      context: ctx,
                      message: 'Duplicate alert',
                      type: CustomSnackBarType.success,
                    );
                  },
                  child: const Text('Spam'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Spam'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Duplicate alert'), findsOneWidget);
  });
}
