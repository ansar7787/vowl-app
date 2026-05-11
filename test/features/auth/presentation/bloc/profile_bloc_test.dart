import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/features/auth/domain/usecases/buy_kids_accessory.dart';
import 'package:vowl/features/auth/domain/usecases/equip_kids_accessory.dart';
import 'package:vowl/features/auth/domain/usecases/update_display_name.dart';
import 'package:vowl/features/auth/domain/usecases/update_kids_mascot.dart';
import 'package:vowl/features/auth/domain/usecases/update_profile_picture.dart';
import 'package:vowl/features/auth/domain/usecases/update_user.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';

class MockUpdateProfilePicture extends Mock implements UpdateProfilePicture {}
class MockUpdateDisplayName extends Mock implements UpdateDisplayName {}
class MockUpdateKidsMascot extends Mock implements UpdateKidsMascot {}
class MockBuyKidsAccessory extends Mock implements BuyKidsAccessory {}
class MockEquipKidsAccessory extends Mock implements EquipKidsAccessory {}
class MockUpdateUser extends Mock implements UpdateUser {}
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late ProfileBloc bloc;
  late MockUpdateProfilePicture mockUpdateProfilePicture;
  late MockUpdateDisplayName mockUpdateDisplayName;
  late MockUpdateKidsMascot mockUpdateKidsMascot;
  late MockBuyKidsAccessory mockBuyKidsAccessory;
  late MockEquipKidsAccessory mockEquipKidsAccessory;
  late MockUpdateUser mockUpdateUser;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockUpdateProfilePicture = MockUpdateProfilePicture();
    mockUpdateDisplayName = MockUpdateDisplayName();
    mockUpdateKidsMascot = MockUpdateKidsMascot();
    mockBuyKidsAccessory = MockBuyKidsAccessory();
    mockEquipKidsAccessory = MockEquipKidsAccessory();
    mockUpdateUser = MockUpdateUser();
    mockAuthBloc = MockAuthBloc();

    bloc = ProfileBloc(
      updateProfilePicture: mockUpdateProfilePicture,
      updateDisplayName: mockUpdateDisplayName,
      updateKidsMascot: mockUpdateKidsMascot,
      buyKidsAccessory: mockBuyKidsAccessory,
      equipKidsAccessory: mockEquipKidsAccessory,
      updateUser: mockUpdateUser,
      authBloc: mockAuthBloc,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('ProfileUpdateDisplayNameRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'should call updateDisplayName and emit message on success',
      build: () {
        when(() => mockUpdateDisplayName(any())).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const ProfileUpdateDisplayNameRequested('New Name')),
      expect: () => [
        isA<ProfileState>().having((s) => s.message, 'message', 'Name updated!'),
      ],
      verify: (_) {
        verify(() => mockUpdateDisplayName('New Name')).called(1);
      },
    );
  });
}
