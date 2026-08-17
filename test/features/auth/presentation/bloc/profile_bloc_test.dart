import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/features/auth/domain/usecases/buy_kids_accessory.dart';
import 'package:vowl/features/auth/domain/usecases/buy_kids_furniture.dart';
import 'package:vowl/features/auth/domain/usecases/buy_vowl_accessory.dart';
import 'package:vowl/features/auth/domain/usecases/buy_vowl_mascot.dart';
import 'package:vowl/features/auth/domain/usecases/equip_kids_accessory.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_golden_key.dart';
import 'package:vowl/features/auth/domain/usecases/add_golden_key.dart';
import 'package:vowl/features/auth/domain/usecases/update_display_name.dart';
import 'package:vowl/features/auth/domain/usecases/update_kids_mascot.dart';
import 'package:vowl/features/auth/domain/usecases/update_profile_picture.dart';
import 'package:vowl/features/auth/domain/usecases/update_user.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class MockUpdateProfilePicture extends Mock implements UpdateProfilePicture {}

class MockUpdateDisplayName extends Mock implements UpdateDisplayName {}

class MockUpdateKidsMascot extends Mock implements UpdateKidsMascot {}

class MockBuyKidsAccessory extends Mock implements BuyKidsAccessory {}

class MockEquipKidsAccessory extends Mock implements EquipKidsAccessory {}

class MockUpdateUser extends Mock implements UpdateUser {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockBuyKidsFurniture extends Mock implements BuyKidsFurniture {}

class MockBuyVowlMascot extends Mock implements BuyVowlMascot {}

class MockBuyVowlAccessory extends Mock implements BuyVowlAccessory {}

class MockPurchaseGoldenKey extends Mock implements PurchaseGoldenKey {}

class MockAddGoldenKey extends Mock implements AddGoldenKey {}

void main() {
  late ProfileBloc bloc;
  late MockUpdateProfilePicture mockUpdateProfilePicture;
  late MockUpdateDisplayName mockUpdateDisplayName;
  late MockUpdateKidsMascot mockUpdateKidsMascot;
  late MockBuyKidsAccessory mockBuyKidsAccessory;
  late MockEquipKidsAccessory mockEquipKidsAccessory;
  late MockUpdateUser mockUpdateUser;
  late MockAuthBloc mockAuthBloc;
  late MockBuyKidsFurniture mockBuyKidsFurniture;
  late MockBuyVowlMascot mockBuyVowlMascot;
  late MockBuyVowlAccessory mockBuyVowlAccessory;
  late MockPurchaseGoldenKey mockPurchaseGoldenKey;
  late MockAddGoldenKey mockAddGoldenKey;

  setUp(() {
    mockUpdateProfilePicture = MockUpdateProfilePicture();
    mockUpdateDisplayName = MockUpdateDisplayName();
    mockUpdateKidsMascot = MockUpdateKidsMascot();
    mockBuyKidsAccessory = MockBuyKidsAccessory();
    mockEquipKidsAccessory = MockEquipKidsAccessory();
    mockUpdateUser = MockUpdateUser();
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(UserEntity(id: '1', email: 'test@vowl.com')));
    mockBuyKidsFurniture = MockBuyKidsFurniture();
    mockBuyVowlMascot = MockBuyVowlMascot();
    mockBuyVowlAccessory = MockBuyVowlAccessory();
    mockPurchaseGoldenKey = MockPurchaseGoldenKey();
    mockAddGoldenKey = MockAddGoldenKey();

    bloc = ProfileBloc(
      updateProfilePicture: mockUpdateProfilePicture,
      updateDisplayName: mockUpdateDisplayName,
      updateKidsMascot: mockUpdateKidsMascot,
      buyKidsAccessory: mockBuyKidsAccessory,
      equipKidsAccessory: mockEquipKidsAccessory,
      updateUser: mockUpdateUser,
      authBloc: mockAuthBloc,
      buyKidsFurniture: mockBuyKidsFurniture,
      buyVowlMascot: mockBuyVowlMascot,
      buyVowlAccessory: mockBuyVowlAccessory,
      purchaseGoldenKey: mockPurchaseGoldenKey,
      addGoldenKey: mockAddGoldenKey,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('ProfileUpdateDisplayNameRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'should call updateDisplayName and emit message on success',
      build: () {
        when(
          () => mockUpdateDisplayName(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const ProfileUpdateDisplayNameRequested('New Name')),
      expect: () => [
        isA<ProfileState>().having(
          (s) => s.message,
          'message',
          'profile.display_name_updated',
        ),
      ],
      verify: (_) {
        verify(() => mockUpdateDisplayName('New Name')).called(1);
      },
    );
  });
}


