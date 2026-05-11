import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/usecases/activate_double_xp.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_streak_freeze.dart';
import 'package:vowl/features/auth/domain/usecases/repair_streak.dart';
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

  setUp(() {
    mockRepairStreak = MockRepairStreak();
    mockPurchaseStreakFreeze = MockPurchaseStreakFreeze();
    mockActivateDoubleXP = MockActivateDoubleXP();
    mockUpdateUser = MockUpdateUser();
    mockAuthBloc = MockAuthBloc();
    mockNotificationService = MockNotificationService();

    bloc = ProgressionBloc(
      repairStreak: mockRepairStreak,
      purchaseStreakFreeze: mockPurchaseStreakFreeze,
      activateDoubleXP: mockActivateDoubleXP,
      updateUser: mockUpdateUser,
      authBloc: mockAuthBloc,
      notificationService: mockNotificationService,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('ProgressionActivateDoubleXPRequested', () {
    blocTest<ProgressionBloc, ProgressionState>(
      'should call activateDoubleXP and emit message on success',
      build: () {
        when(() => mockActivateDoubleXP(any())).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const ProgressionActivateDoubleXPRequested(100)),
      expect: () => [
        isA<ProgressionState>().having((s) => s.message, 'message', 'Double XP Activated!'),
      ],
      verify: (_) {
        verify(() => mockActivateDoubleXP(any())).called(1);
      },
    );
  });
}
