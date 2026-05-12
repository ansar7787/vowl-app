import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/usecases/claim_daily_gift.dart';
import 'package:vowl/features/auth/domain/usecases/claim_vip_gift.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_hint.dart';
import 'package:vowl/features/auth/domain/usecases/update_user.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/claim_daily_chest.dart';
import 'package:vowl/features/auth/domain/usecases/claim_kids_daily_reward.dart';
import 'package:vowl/features/auth/domain/usecases/award_kids_coins.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class MockUpdateUserCoins extends Mock implements UpdateUserCoins {}
class MockPurchaseHint extends Mock implements PurchaseHint {}
class MockClaimVipGift extends Mock implements ClaimVipGift {}
class MockClaimDailyGift extends Mock implements ClaimDailyGift {}
class MockUpdateUser extends Mock implements UpdateUser {}
class MockClaimDailyChest extends Mock implements ClaimDailyChest {}
class MockClaimKidsDailyReward extends Mock implements ClaimKidsDailyReward {}
class MockAwardKidsCoins extends Mock implements AwardKidsCoins {}
class MockUseHint extends Mock implements UseHint {}
class MockAuthBloc extends Mock implements AuthBloc {}

class FakeNoParams extends Fake implements NoParams {}
class FakeUpdateUserCoinsParams extends Fake implements UpdateUserCoinsParams {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(FakeUpdateUserCoinsParams());
  });

  late EconomyBloc bloc;
  late MockUpdateUserCoins mockUpdateUserCoins;
  late MockPurchaseHint mockPurchaseHint;
  late MockClaimVipGift mockClaimVipGift;
  late MockClaimDailyGift mockClaimDailyGift;
  late MockUpdateUser mockUpdateUser;
  late MockClaimDailyChest mockClaimDailyChest;
  late MockClaimKidsDailyReward mockClaimKidsDailyReward;
  late MockAwardKidsCoins mockAwardKidsCoins;
  late MockUseHint mockUseHint;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockUpdateUserCoins = MockUpdateUserCoins();
    mockPurchaseHint = MockPurchaseHint();
    mockClaimVipGift = MockClaimVipGift();
    mockClaimDailyGift = MockClaimDailyGift();
    mockUpdateUser = MockUpdateUser();
    mockClaimDailyChest = MockClaimDailyChest();
    mockClaimKidsDailyReward = MockClaimKidsDailyReward();
    mockAwardKidsCoins = MockAwardKidsCoins();
    mockUseHint = MockUseHint();
    mockAuthBloc = MockAuthBloc();

    bloc = EconomyBloc(
      updateUserCoins: mockUpdateUserCoins,
      purchaseHint: mockPurchaseHint,
      claimVipGift: mockClaimVipGift,
      claimDailyGift: mockClaimDailyGift,
      updateUser: mockUpdateUser,
      claimDailyChest: mockClaimDailyChest,
      claimKidsDailyReward: mockClaimKidsDailyReward,
      awardKidsCoins: mockAwardKidsCoins,
      useHint: mockUseHint,
      authBloc: mockAuthBloc,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('EconomyAddCoinsRequested', () {
    blocTest<EconomyBloc, EconomyState>(
      'should call updateUserCoins and emit no message on success',
      build: () {
        when(() => mockUpdateUserCoins(any())).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const EconomyAddCoinsRequested(100)),
      expect: () => [],
      verify: (_) {
        verify(() => mockUpdateUserCoins(any())).called(1);
      },
    );
  });
}
