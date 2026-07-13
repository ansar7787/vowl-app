import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/usecases/activate_double_xp.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_streak_freeze.dart';
import 'package:vowl/features/auth/domain/usecases/repair_streak.dart';
import 'package:vowl/features/auth/domain/usecases/repair_streak_free.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_permanent_xp_boost.dart';
import 'package:vowl/features/auth/domain/usecases/claim_streak_milestone.dart';
import 'package:vowl/features/auth/domain/usecases/claim_level_milestone.dart';
import 'package:vowl/features/auth/domain/usecases/update_user.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/core/utils/notification_service.dart';

class MockRepairStreak extends Mock implements RepairStreak {}

class MockPurchaseStreakFreeze extends Mock implements PurchaseStreakFreeze {}

class MockActivateDoubleXP extends Mock implements ActivateDoubleXP {}

class MockUpdateUser extends Mock implements UpdateUser {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockNotificationService extends Mock implements NotificationService {}

class MockRepairStreakFree extends Mock implements RepairStreakFree {}

class MockPurchasePermanentXPBoost extends Mock
    implements PurchasePermanentXPBoost {}

class MockClaimStreakMilestone extends Mock implements ClaimStreakMilestone {}

class MockClaimLevelMilestone extends Mock implements ClaimLevelMilestone {}

class FakeNoParams extends Fake implements NoParams {}

class FakeUpdateUserParams extends Fake implements UpdateUserParams {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(FakeUpdateUserParams());
  });

  late ProgressionBloc bloc;
  late MockRepairStreak mockRepairStreak;
  late MockPurchaseStreakFreeze mockPurchaseStreakFreeze;
  late MockActivateDoubleXP mockActivateDoubleXP;
  late MockUpdateUser mockUpdateUser;
  late MockAuthBloc mockAuthBloc;
  late MockNotificationService mockNotificationService;
  late MockRepairStreakFree mockRepairStreakFree;
  late MockPurchasePermanentXPBoost mockPurchasePermanentXPBoost;
  late MockClaimStreakMilestone mockClaimStreakMilestone;
  late MockClaimLevelMilestone mockClaimLevelMilestone;

  setUp(() {
    mockRepairStreak = MockRepairStreak();
    mockPurchaseStreakFreeze = MockPurchaseStreakFreeze();
    mockActivateDoubleXP = MockActivateDoubleXP();
    mockUpdateUser = MockUpdateUser();
    mockAuthBloc = MockAuthBloc();
    mockNotificationService = MockNotificationService();
    mockRepairStreakFree = MockRepairStreakFree();
    mockPurchasePermanentXPBoost = MockPurchasePermanentXPBoost();
    mockClaimStreakMilestone = MockClaimStreakMilestone();
    mockClaimLevelMilestone = MockClaimLevelMilestone();

    bloc = ProgressionBloc(
      repairStreak: mockRepairStreak,
      purchaseStreakFreeze: mockPurchaseStreakFreeze,
      activateDoubleXP: mockActivateDoubleXP,
      updateUser: mockUpdateUser,
      authBloc: mockAuthBloc,
      notificationService: mockNotificationService,
      repairStreakFree: mockRepairStreakFree,
      purchasePermanentXPBoost: mockPurchasePermanentXPBoost,
      claimStreakMilestone: mockClaimStreakMilestone,
      claimLevelMilestone: mockClaimLevelMilestone,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('ProgressionActivateDoubleXPRequested', () {
    blocTest<ProgressionBloc, ProgressionState>(
      'should call activateDoubleXP and emit message on success',
      build: () {
        when(
          () => mockActivateDoubleXP(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const ProgressionActivateDoubleXPRequested(100)),
      expect: () => [
        isA<ProgressionState>().having(
          (s) => s.message,
          'message',
          'progression.double_xp_activated',
        ),
      ],
      verify: (_) {
        verify(() => mockActivateDoubleXP(any())).called(1);
      },
    );
  });
}
