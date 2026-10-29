import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/home/presentation/widgets/mystery_chest_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ConfettiController confettiController;
  bool wasOpened = false;
  bool wasClosed = false;

  setUp(() {
    confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    wasOpened = false;
    wasClosed = false;
  });

  tearDown(() {
    confettiController.dispose();
  });

  Widget createSubject({
    required bool isOpened,
    bool isPremium = false,
    int rewardAmount = 50,
  }) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      builder: (context, _) => MaterialApp(
        home: MysteryChestOverlay(
          isOpened: isOpened,
          isPremium: isPremium,
          rewardAmount: rewardAmount,
          onOpen: () => wasOpened = true,
          onClose: () => wasClosed = true,
          confettiController: confettiController,
        ),
      ),
    );
  }

  testWidgets('renders closed chest initially with tap prompt and titles',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSubject(isOpened: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MysteryChestOverlay), findsOneWidget);
    expect(find.text('DAILY MYSTERY'), findsOneWidget);
    expect(find.text('READY TO OPEN?'), findsOneWidget);
    expect(find.text('TAP TO UNVEIL'), findsOneWidget);
  });

  testWidgets('renders VIP title for premium users in closed state',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSubject(isOpened: false, isPremium: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('VIP DAILY GIFT'), findsOneWidget);
    expect(find.text('YOUR EXCLUSIVE PRO REWARD'), findsOneWidget);
  });

  testWidgets('tapping closed chest prompt triggers onOpen callback',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createSubject(isOpened: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('TAP TO UNVEIL'));
    await tester.pump();
    expect(wasOpened, isTrue);
  });

  testWidgets(
      'renders reward card, rolling coins and COLLECT button when opened',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createSubject(isOpened: true, rewardAmount: 42),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Reward card should display +42 and coins collected label
    expect(find.text('+42'), findsOneWidget);
    expect(find.text('Coins Collected'), findsOneWidget);

    // COLLECT CTA button should be rendered
    expect(find.text('COLLECT'), findsOneWidget);
    expect(find.text('Tap anywhere to continue'), findsOneWidget);
  });

  testWidgets('tapping COLLECT button triggers onClose callback',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createSubject(isOpened: true, rewardAmount: 25),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('COLLECT'));
    await tester.pump();
    expect(wasClosed, isTrue);
  });

  testWidgets('tapping top-right close icon triggers onClose callback',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createSubject(isOpened: true, rewardAmount: 25),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final closeIcon = find.byIcon(Icons.close_rounded);
    expect(closeIcon, findsOneWidget);

    await tester.tap(closeIcon);
    await tester.pump();
    expect(wasClosed, isTrue);
  });

  testWidgets('renders VIP badge and VIP unlocked title for premium users',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      createSubject(isOpened: true, isPremium: true, rewardAmount: 100),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('VIP VAULT UNLOCKED!'), findsOneWidget);
    expect(find.text('3X VIP'), findsOneWidget);
    expect(find.text('+100'), findsOneWidget);
    expect(find.text('VIP Bonus Coins Collected'), findsOneWidget);
  });
}
