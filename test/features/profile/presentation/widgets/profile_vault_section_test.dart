import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/profile/presentation/widgets/profile_vault_section.dart';

class MockHapticService extends Mock implements HapticService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;

  final testUserZeroReferrals = UserEntity(
    id: 'user_vault_0',
    email: 'zero@vowl.app',
    displayName: 'Zero Referral Hero',
    referralCode: 'VOWL-ZERO',
    totalReferralsCount: 0,
    coins: 50,
  );

  final testUserWithReferrals = UserEntity(
    id: 'user_vault_3',
    email: 'three@vowl.app',
    displayName: 'Referral Master',
    referralCode: 'VOWL-PRO',
    totalReferralsCount: 3,
    coins: 350,
  );

  final testUserWithKidsData = UserEntity(
    id: 'user_vault_kids',
    email: 'kids@vowl.app',
    displayName: 'Kids Hero',
    referralCode: 'VOWL-KIDS',
    totalReferralsCount: 1,
    coins: 100,
    kidsStickers: const ['sticker_star_1'],
  );

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockHapticService = MockHapticService();
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
  });

  Widget buildSubject({required UserEntity user}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: SingleChildScrollView(child: ProfileVaultSection(user: user)),
          ),
        ),
        GoRoute(
          path: AppRouter.kidsZoneRoute,
          builder: (context, _) => const Scaffold(body: Text('Kids Zone Page')),
        ),
        GoRoute(
          path: '/kids-room',
          builder: (context, _) => const Scaffold(body: Text('Kids Room Page')),
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(393, 852),
      builder: (context, _) => MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('ProfileVaultSection Invite & Earn and Monthly Cup Tests', () {
    testWidgets('renders short 1-line invite subtitle with Lucide coins icon', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(user: testUserZeroReferrals));
      await tester.pumpAndSettle();

      // Invite & Earn Header
      expect(find.text('INVITE & EARN'), findsOneWidget);
      expect(find.text('Invite Friends, Earn VIP'), findsOneWidget);

      // Short 1-line subtitle rich text containing coin icon
      expect(find.textContaining('You both get +100'), findsOneWidget);
      expect(find.textContaining('& 1 Day VIP'), findsOneWidget);
      expect(find.byIcon(LucideIcons.coins), findsWidgets);

      // Verify old long multi-line copy is NOT present
      expect(find.textContaining('when they join'), findsNothing);
    });

    testWidgets('monthly cup displays without arrow for zero referrals', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(user: testUserZeroReferrals));
      await tester.pumpAndSettle();

      // Monthly Cup without arrow
      expect(find.text('Monthly Cup'), findsOneWidget);
      expect(find.text('Monthly Cup →'), findsNothing);
      expect(find.textContaining('→'), findsNothing);
    });

    testWidgets('monthly cup displays without arrow when user has referrals', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(user: testUserWithReferrals));
      await tester.pumpAndSettle();

      // Joined Cup without arrow
      expect(find.text('3 Joined • Cup'), findsOneWidget);
      expect(find.text('3 Joined • Cup →'), findsNothing);
      expect(find.textContaining('→'), findsNothing);
    });

    testWidgets('renders Kids Learning Zone and Kids Room feature cards', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(user: testUserWithKidsData));
      await tester.pumpAndSettle();

      // Kids Zone Section Header
      expect(find.text('Kids Zone'), findsOneWidget);

      // Kids Learning Zone Card
      expect(find.text('Kids Learning Zone'), findsOneWidget);
      expect(
        find.textContaining('Phonics, alphabet, animals'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.child_care_rounded), findsOneWidget);

      // Kids Room Card
      expect(find.text('Kids Room'), findsOneWidget);
      expect(find.byIcon(Icons.toys_rounded), findsOneWidget);
    });

    testWidgets('tapping Kids Learning Zone card invokes selection haptic', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(user: testUserWithKidsData));
      await tester.pumpAndSettle();

      final learningZoneCard = find.text('Kids Learning Zone');
      expect(learningZoneCard, findsOneWidget);

      await tester.ensureVisible(learningZoneCard);
      await tester.pumpAndSettle();

      await tester.tap(learningZoneCard);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);
    });
  });
}
