import 'dart:async';
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
import 'package:vowl/core/network/network_info.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockUpdateProfilePicture extends Mock implements UpdateProfilePicture {}

class MockUpdateDisplayName extends Mock implements UpdateDisplayName {}

class MockUpdateKidsMascot extends Mock implements UpdateKidsMascot {}

class MockBuyKidsAccessory extends Mock implements BuyKidsAccessory {}

class MockEquipKidsAccessory extends Mock implements EquipKidsAccessory {}

class MockUpdateUser extends Mock implements UpdateUser {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

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
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<AuthState> authStateController;

  setUp(() {
    mockNetworkInfo = MockNetworkInfo();
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    mockUpdateProfilePicture = MockUpdateProfilePicture();
    mockUpdateDisplayName = MockUpdateDisplayName();
    mockUpdateKidsMascot = MockUpdateKidsMascot();
    mockBuyKidsAccessory = MockBuyKidsAccessory();
    mockEquipKidsAccessory = MockEquipKidsAccessory();
    mockUpdateUser = MockUpdateUser();
    mockAuthBloc = MockAuthBloc();
    mockBuyKidsFurniture = MockBuyKidsFurniture();
    mockBuyVowlMascot = MockBuyVowlMascot();
    mockBuyVowlAccessory = MockBuyVowlAccessory();
    mockPurchaseGoldenKey = MockPurchaseGoldenKey();
    mockAddGoldenKey = MockAddGoldenKey();
    authStateController = StreamController<AuthState>.broadcast();

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(id: '1', email: 'test@vowl.com'),
      ),
    );
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => authStateController.stream);

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
      networkInfo: mockNetworkInfo,
    );
  });

  tearDown(() {
    bloc.close();
    authStateController.close();
  });

  group('ProfileState and isPhotoForUser', () {
    test(
      'isPhotoForUser returns true only when userId matches photoUserId',
      () {
        const stateWithPhoto = ProfileState(
          photoUrl: 'https://vowl.app/avatar.jpg',
          photoUserId: 'user_1',
        );
        expect(stateWithPhoto.isPhotoForUser('user_1'), isTrue);
        expect(stateWithPhoto.isPhotoForUser('user_2'), isFalse);
        expect(stateWithPhoto.isPhotoForUser(null), isFalse);

        const stateWithoutPhoto = ProfileState(
          photoUrl: null,
          photoUserId: 'user_1',
        );
        expect(stateWithoutPhoto.isPhotoForUser('user_1'), isFalse);

        const stateWithoutUserId = ProfileState(
          photoUrl: 'https://vowl.app/avatar.jpg',
          photoUserId: null,
        );
        expect(stateWithoutUserId.isPhotoForUser('user_1'), isFalse);
      },
    );
  });

  group('ProfileUpdateDisplayNameRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'should call updateDisplayName and emit message on success with isPhotoUploading: false',
      build: () {
        when(
          () => mockUpdateDisplayName(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const ProfileUpdateDisplayNameRequested('New Name')),
      expect: () => [
        isA<ProfileState>()
            .having((s) => s.isLoading, 'isLoading', true)
            .having((s) => s.isPhotoUploading, 'isPhotoUploading', false)
            .having((s) => s.message, 'message', isNull),
        isA<ProfileState>()
            .having((s) => s.message, 'message', 'profile.display_name_updated')
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.isPhotoUploading, 'isPhotoUploading', false),
      ],
      verify: (_) {
        verify(() => mockUpdateDisplayName('New Name')).called(1);
      },
    );
  });

  group('ProfileUpdatePictureRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'should set isPhotoUploading: true, then photoUrl and isPhotoUploading: false on success',
      build: () {
        when(
          () => mockUpdateProfilePicture(any()),
        ).thenAnswer((_) async => const Right('https://vowl.app/avatar.jpg'));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const ProfileUpdatePictureRequested('/path/to/pic.png')),
      expect: () => [
        isA<ProfileState>()
            .having((s) => s.isLoading, 'isLoading', true)
            .having((s) => s.isPhotoUploading, 'isPhotoUploading', true)
            .having((s) => s.message, 'message', isNull),
        isA<ProfileState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.isPhotoUploading, 'isPhotoUploading', false)
            .having((s) => s.message, 'message', 'profile.picture_updated')
            .having(
              (s) => s.photoUrl,
              'photoUrl',
              'https://vowl.app/avatar.jpg',
            )
            .having((s) => s.photoUserId, 'photoUserId', '1'),
      ],
      verify: (_) {
        verify(() => mockUpdateProfilePicture('/path/to/pic.png')).called(1);
        verify(() => mockAuthBloc.add(const AuthReloadUser())).called(1);
      },
    );
  });

  group('ProfileClearMessage', () {
    blocTest<ProfileBloc, ProfileState>(
      'should clear message when ProfileClearMessage is dispatched',
      seed: () => const ProfileState(message: 'profile.picture_updated'),
      build: () => bloc,
      act: (bloc) => bloc.add(const ProfileClearMessage()),
      expect: () => [
        isA<ProfileState>().having((s) => s.message, 'message', isNull),
      ],
    );
  });

  group('ProfileClearImmediatePhoto', () {
    blocTest<ProfileBloc, ProfileState>(
      'should clear photoUrl and photoUserId when requested',
      seed: () => const ProfileState(
        photoUrl: 'https://vowl.app/avatar.jpg',
        photoUserId: '1',
      ),
      build: () => bloc,
      act: (bloc) => bloc.add(const ProfileClearImmediatePhoto()),
      expect: () => [
        isA<ProfileState>()
            .having((s) => s.photoUrl, 'photoUrl', isNull)
            .having((s) => s.photoUserId, 'photoUserId', isNull),
      ],
    );
  });
}
