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
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class MockUpdateUserCoins extends Mock implements UpdateUserCoins {}
class MockPurchaseHint extends Mock implements PurchaseHint {}
class MockClaimVipGift extends Mock implements ClaimVipGift {}
class MockClaimDailyGift extends Mock implements ClaimDailyGift {}
class MockUpdateUser extends Mock implements UpdateUser {}
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
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockUpdateUserCoins = MockUpdateUserCoins();
    mockPurchaseHint = MockPurchaseHint();
    mockClaimVipGift = MockClaimVipGift();
    mockClaimDailyGift = MockClaimDailyGift();
    mockUpdateUser = MockUpdateUser();
    mockAuthBloc = MockAuthBloc();

    bloc = EconomyBloc(
      updateUserCoins: mockUpdateUserCoins,
      purchaseHint: mockPurchaseHint,
      claimVipGift: mockClaimVipGift,
      claimDailyGift: mockClaimDailyGift,
      updateUser: mockUpdateUser,
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
