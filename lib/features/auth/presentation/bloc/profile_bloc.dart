import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/domain/usecases/buy_kids_accessory.dart';
import 'package:vowl/features/auth/domain/usecases/equip_kids_accessory.dart';
import 'package:vowl/features/auth/domain/usecases/update_display_name.dart';
import 'package:vowl/features/auth/domain/usecases/update_kids_mascot.dart';
import 'package:vowl/features/auth/domain/usecases/update_profile_picture.dart';
import 'package:vowl/features/auth/domain/usecases/update_user.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

// ============================================================================
// EVENTS
// ============================================================================

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileClearPurchaseFeedback extends ProfileEvent {
  const ProfileClearPurchaseFeedback();
}

class ProfileUpdateDisplayNameRequested extends ProfileEvent {
  final String displayName;
  const ProfileUpdateDisplayNameRequested(this.displayName);
  @override
  List<Object?> get props => [displayName];
}

class ProfileUpdatePictureRequested extends ProfileEvent {
  final String filePath;
  const ProfileUpdatePictureRequested(this.filePath);
  @override
  List<Object?> get props => [filePath];
}

class ProfileUpdateMascotRequested extends ProfileEvent {
  final String mascotId;
  const ProfileUpdateMascotRequested(this.mascotId);
  @override
  List<Object?> get props => [mascotId];
}

class ProfileBuyAccessoryRequested extends ProfileEvent {
  final String accessoryId;
  final int cost;
  const ProfileBuyAccessoryRequested(this.accessoryId, this.cost);
  @override
  List<Object?> get props => [accessoryId, cost];
}

class ProfileEquipAccessoryRequested extends ProfileEvent {
  final String? accessoryId;
  const ProfileEquipAccessoryRequested(this.accessoryId);
  @override
  List<Object?> get props => [accessoryId];
}

class ProfileUpdateFurnitureRequested extends ProfileEvent {
  final String category;
  final String furnitureId;
  const ProfileUpdateFurnitureRequested(this.category, this.furnitureId);
  @override
  List<Object?> get props => [category, furnitureId];
}

class ProfileBuyFurnitureRequested extends ProfileEvent {
  final String category;
  final String furnitureId;
  final int cost;
  const ProfileBuyFurnitureRequested(
    this.category,
    this.furnitureId,
    this.cost,
  );
  @override
  List<Object?> get props => [category, furnitureId, cost];
}

class ProfileUpdateVowlMascotRequested extends ProfileEvent {
  final String mascotId;
  const ProfileUpdateVowlMascotRequested(this.mascotId);
  @override
  List<Object?> get props => [mascotId];
}

class ProfileBuyVowlAccessoryRequested extends ProfileEvent {
  final String accessoryId;
  final int cost;
  const ProfileBuyVowlAccessoryRequested(this.accessoryId, this.cost);
  @override
  List<Object?> get props => [accessoryId, cost];
}

class ProfileEquipVowlAccessoryRequested extends ProfileEvent {
  final String? accessoryId;
  const ProfileEquipVowlAccessoryRequested(this.accessoryId);
  @override
  List<Object?> get props => [accessoryId];
}

class ProfileEquipStickerRequested extends ProfileEvent {
  final String? stickerId;
  const ProfileEquipStickerRequested(this.stickerId);
  @override
  List<Object?> get props => [stickerId];
}

// ============================================================================
// STATE
// ============================================================================

class ProfileState extends Equatable {
  final String? message;
  final bool isLoading;
  final String? lastPurchaseType;
  final bool? lastPurchaseSuccess;

  const ProfileState({
    this.message,
    this.isLoading = false,
    this.lastPurchaseType,
    this.lastPurchaseSuccess,
  });

  ProfileState copyWith({
    String? Function()? message,
    bool? isLoading,
    String? Function()? lastPurchaseType,
    bool? Function()? lastPurchaseSuccess,
  }) {
    return ProfileState(
      message: message != null ? message() : this.message,
      isLoading: isLoading ?? this.isLoading,
      lastPurchaseType: lastPurchaseType != null
          ? lastPurchaseType()
          : this.lastPurchaseType,
      lastPurchaseSuccess: lastPurchaseSuccess != null
          ? lastPurchaseSuccess()
          : this.lastPurchaseSuccess,
    );
  }

  @override
  List<Object?> get props => [
    message,
    isLoading,
    lastPurchaseType,
    lastPurchaseSuccess,
  ];
}

// ============================================================================
// BLOC
// ============================================================================

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UpdateDisplayName updateDisplayName;
  final UpdateProfilePicture updateProfilePicture;
  final UpdateKidsMascot updateKidsMascot;
  final BuyKidsAccessory buyKidsAccessory;
  final EquipKidsAccessory equipKidsAccessory;
  final UpdateUser updateUser;
  final AuthBloc authBloc;

  ProfileBloc({
    required this.updateDisplayName,
    required this.updateProfilePicture,
    required this.updateKidsMascot,
    required this.buyKidsAccessory,
    required this.equipKidsAccessory,
    required this.updateUser,
    required this.authBloc,
  }) : super(const ProfileState()) {
    on<ProfileUpdateDisplayNameRequested>(_onUpdateDisplayName);
    on<ProfileUpdatePictureRequested>(_onUpdatePicture);
    on<ProfileUpdateMascotRequested>(_onUpdateMascot);
    on<ProfileBuyAccessoryRequested>(_onBuyAccessory);
    on<ProfileEquipAccessoryRequested>(_onEquipAccessory);
    on<ProfileUpdateFurnitureRequested>(_onUpdateFurniture);
    on<ProfileBuyFurnitureRequested>(_onBuyFurniture);
    on<ProfileUpdateVowlMascotRequested>(_onUpdateVowlMascot);
    on<ProfileBuyVowlAccessoryRequested>(_onBuyVowlAccessory);
    on<ProfileEquipVowlAccessoryRequested>(_onEquipVowlAccessory);
    on<ProfileEquipStickerRequested>(_onEquipSticker);
    on<ProfileClearPurchaseFeedback>(
      (_, emit) => emit(
        state.copyWith(
          lastPurchaseType: () => null,
          lastPurchaseSuccess: () => null,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Guard
  // ---------------------------------------------------------------------------

  bool get _isAuthenticated =>
      authBloc.state.status == AuthStatus.authenticated;

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onUpdateDisplayName(
    ProfileUpdateDisplayNameRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await updateDisplayName(event.displayName);
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) {
        emit(state.copyWith(message: () => 'Name updated!'));
        authBloc.add(const AuthReloadUser());
      },
    );
  }

  Future<void> _onUpdatePicture(
    ProfileUpdatePictureRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await updateProfilePicture(event.filePath);
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) {
        emit(state.copyWith(message: () => 'Profile picture updated!'));
        authBloc.add(const AuthReloadUser());
      },
    );
  }

  Future<void> _onUpdateMascot(
    ProfileUpdateMascotRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await updateKidsMascot(event.mascotId);
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => authBloc.add(const AuthReloadUser()),
    );
  }

  Future<void> _onBuyAccessory(
    ProfileBuyAccessoryRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await buyKidsAccessory(
      BuyKidsAccessoryParams(accessoryId: event.accessoryId, cost: event.cost),
    );
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => authBloc.add(const AuthReloadUser()),
    );
  }

  Future<void> _onEquipAccessory(
    ProfileEquipAccessoryRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await equipKidsAccessory(event.accessoryId);
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => authBloc.add(const AuthReloadUser()),
    );
  }

  Future<void> _onUpdateFurniture(
    ProfileUpdateFurnitureRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final user = authBloc.state.user;
    if (user == null) return;

    final newEquipped = Map<String, String>.from(user.kidsEquippedFurniture)
      ..[event.category] = event.furnitureId;
    final updatedUser = user.copyWith(kidsEquippedFurniture: newEquipped);
    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => authBloc.add(const AuthReloadUser()),
    );
  }

  /// Purchases a furniture item by deducting [event.cost] from [kidsCoins]
  /// client-side and persisting the full user document.
  ///
  /// ⚠️ The coin deduction is performed client-side (read-then-write without
  /// a Firestore transaction). A concurrent purchase on another device could
  /// allow the balance to go negative. Add a dedicated
  /// `ShopRepository.buyFurniture()` transaction method to fix this.
  Future<void> _onBuyFurniture(
    ProfileBuyFurnitureRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final user = authBloc.state.user;
    if (user == null) return;

    if (user.kidsCoins < event.cost) {
      emit(state.copyWith(message: () => 'Not enough coins!'));
      return;
    }

    final newOwned = [...user.kidsOwnedFurniture, event.furnitureId];
    final newEquipped = Map<String, String>.from(user.kidsEquippedFurniture)
      ..[event.category] = event.furnitureId;

    final updatedUser = user.copyWith(
      kidsCoins: user.kidsCoins - event.cost,
      kidsOwnedFurniture: newOwned,
      kidsEquippedFurniture: newEquipped,
    );

    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => authBloc.add(const AuthReloadUser()),
    );
  }

  Future<void> _onUpdateVowlMascot(
    ProfileUpdateVowlMascotRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final user = authBloc.state.user;
    if (user == null) return;

    final updatedUser = user.copyWith(vowlMascot: event.mascotId);
    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => authBloc.add(const AuthReloadUser()),
    );
  }

  /// Purchases a Vowl accessory by deducting [event.cost] from [coins]
  /// client-side.
  ///
  /// ⚠️ Same concurrency caveat as [_onBuyFurniture]. Requires a
  /// server-side transaction for production safety.
  Future<void> _onBuyVowlAccessory(
    ProfileBuyVowlAccessoryRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final user = authBloc.state.user;
    if (user == null) return;

    if (user.coins < event.cost) {
      emit(
        state.copyWith(
          message: () => 'Not enough coins!',
          lastPurchaseType: () => 'vowl_accessory',
          lastPurchaseSuccess: () => false,
        ),
      );
      return;
    }

    final newOwned = [...user.vowlOwnedAccessories, event.accessoryId];
    final updatedUser = user.copyWith(
      coins: user.coins - event.cost,
      vowlOwnedAccessories: newOwned,
      vowlEquippedAccessory: event.accessoryId,
    );

    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(
        state.copyWith(
          message: () => failure.message,
          lastPurchaseType: () => 'vowl_accessory',
          lastPurchaseSuccess: () => false,
        ),
      ),
      (_) {
        authBloc.add(const AuthReloadUser());
        emit(
          state.copyWith(
            lastPurchaseType: () => 'vowl_accessory',
            lastPurchaseSuccess: () => true,
          ),
        );
      },
    );
  }

  Future<void> _onEquipVowlAccessory(
    ProfileEquipVowlAccessoryRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final user = authBloc.state.user;
    if (user == null) return;

    final updatedUser = user.copyWith(vowlEquippedAccessory: event.accessoryId);
    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => authBloc.add(const AuthReloadUser()),
    );
  }

  Future<void> _onEquipSticker(
    ProfileEquipStickerRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final user = authBloc.state.user;
    if (user == null) return;

    final updatedUser = user.copyWith(kidsEquippedSticker: event.stickerId);
    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => authBloc.add(const AuthReloadUser()),
    );
  }
}
