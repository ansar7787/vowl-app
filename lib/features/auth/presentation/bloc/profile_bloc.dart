import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/features/auth/domain/usecases/add_golden_key.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/domain/usecases/buy_kids_accessory.dart';
import 'package:vowl/features/auth/domain/usecases/buy_kids_furniture.dart';
import 'package:vowl/features/auth/domain/usecases/buy_vowl_accessory.dart';
import 'package:vowl/features/auth/domain/usecases/buy_vowl_mascot.dart';
import 'package:vowl/features/auth/domain/usecases/equip_kids_accessory.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_golden_key.dart';
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

class ProfileBuyVowlMascotRequested extends ProfileEvent {
  final String mascotId;
  final int cost;
  const ProfileBuyVowlMascotRequested(this.mascotId, this.cost);
  @override
  List<Object?> get props => [mascotId, cost];
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

class ProfileUpdateKeysRequested extends ProfileEvent {
  final int amount;
  const ProfileUpdateKeysRequested(this.amount);
  @override
  List<Object?> get props => [amount];
}

class ProfileBuyKeyRequested extends ProfileEvent {
  final int cost;
  final bool isKidsMode;
  const ProfileBuyKeyRequested({required this.cost, required this.isKidsMode});
  @override
  List<Object?> get props => [cost, isKidsMode];
}

/// Atomically updates one or more buddy-room lifecycle fields.
///
/// Accepts a partial update map — only the fields the caller passes are
/// mutated; everything else preserves its current value. This avoids
/// creating a separate event class for every single buddy-room field.
class ProfileUpdateBuddyRoomRequested extends ProfileEvent {
  final String? mood;
  final int? energy;
  final int? hunger;
  final int? careStreak;
  final int? roomLevel;
  final String? theme;
  final DateTime? lastCareDate;
  final DateTime? lastFeedTime;
  final int? gamesPlayedToday;
  final DateTime? lastGameDate;

  const ProfileUpdateBuddyRoomRequested({
    this.mood,
    this.energy,
    this.hunger,
    this.careStreak,
    this.roomLevel,
    this.theme,
    this.lastCareDate,
    this.lastFeedTime,
    this.gamesPlayedToday,
    this.lastGameDate,
  });

  @override
  List<Object?> get props => [
    mood, energy, hunger, careStreak, roomLevel, theme,
    lastCareDate, lastFeedTime, gamesPlayedToday, lastGameDate,
  ];
}

// ============================================================================
// STATE
// ============================================================================

class ProfileState extends Equatable {
  final String? message;
  final bool isLoading;
  final String? lastPurchaseType;
  final bool? lastPurchaseSuccess;

  /// The freshly-uploaded profile picture's download URL, available
  /// immediately on a successful [ProfileUpdatePictureRequested] — before
  /// [AuthBloc]'s reload round-trip completes. Previously
  /// [UpdateProfilePicture]'s [Right] value (documented on that use case as
  /// existing specifically so "the presentation layer can update the UI
  /// immediately without waiting for [GetUserStream] to re-emit") was
  /// discarded entirely in [_onUpdatePicture] — this state had nowhere to
  /// put it. Purely additive: any existing UI that doesn't read this new
  /// field behaves exactly as before.
  final String? photoUrl;

  const ProfileState({
    this.message,
    this.isLoading = false,
    this.lastPurchaseType,
    this.lastPurchaseSuccess,
    this.photoUrl,
  });

  ProfileState copyWith({
    String? Function()? message,
    bool? isLoading,
    String? Function()? lastPurchaseType,
    bool? Function()? lastPurchaseSuccess,
    String? Function()? photoUrl,
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
      photoUrl: photoUrl != null ? photoUrl() : this.photoUrl,
    );
  }

  @override
  List<Object?> get props => [
    message,
    isLoading,
    lastPurchaseType,
    lastPurchaseSuccess,
    photoUrl,
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

  // Added to replace unsafe client-side purchase/credit logic previously
  // implemented via a generic `updateUser` full-document write — see each
  // handler's doc comment below for what specifically changed and why.
  final BuyKidsFurniture buyKidsFurniture;
  final BuyVowlMascot buyVowlMascot;
  final BuyVowlAccessory buyVowlAccessory;
  final PurchaseGoldenKey purchaseGoldenKey;
  final AddGoldenKey addGoldenKey;

  ProfileBloc({
    required this.updateDisplayName,
    required this.updateProfilePicture,
    required this.updateKidsMascot,
    required this.buyKidsAccessory,
    required this.equipKidsAccessory,
    required this.updateUser,
    required this.authBloc,
    required this.buyKidsFurniture,
    required this.buyVowlMascot,
    required this.buyVowlAccessory,
    required this.purchaseGoldenKey,
    required this.addGoldenKey,
  }) : super(const ProfileState()) {
    on<ProfileUpdateDisplayNameRequested>(_onUpdateDisplayName);
    on<ProfileUpdatePictureRequested>(_onUpdatePicture);
    on<ProfileUpdateMascotRequested>(_onUpdateMascot);
    on<ProfileBuyAccessoryRequested>(_onBuyAccessory);
    on<ProfileEquipAccessoryRequested>(_onEquipAccessory);
    on<ProfileUpdateFurnitureRequested>(_onUpdateFurniture);
    on<ProfileBuyFurnitureRequested>(_onBuyFurniture);
    on<ProfileUpdateVowlMascotRequested>(_onUpdateVowlMascot);
    on<ProfileBuyVowlMascotRequested>(_onBuyVowlMascot);
    on<ProfileBuyVowlAccessoryRequested>(_onBuyVowlAccessory);
    on<ProfileEquipVowlAccessoryRequested>(_onEquipVowlAccessory);
    on<ProfileEquipStickerRequested>(_onEquipSticker);
    on<ProfileUpdateKeysRequested>(_onUpdateKeys);
    on<ProfileBuyKeyRequested>(_onBuyKey);
    on<ProfileUpdateBuddyRoomRequested>(_onUpdateBuddyRoom);
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
        // 'profile.display_name_updated' is a stable key, not English
        // display text — see GamificationRepositoryImpl's class doc for the
        // full localization rationale applied consistently across this
        // review; the previous literal ('Name updated!') could never be
        // localized for any of this app's other 17 target languages.
        emit(state.copyWith(message: () => 'profile.display_name_updated'));
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
      (downloadUrl) {
        // Previously this branch was `(_) { ... }` — discarding the
        // download URL entirely and relying solely on AuthReloadUser's
        // round trip. That throws away exactly the immediacy
        // UpdateProfilePicture's own doc comment says this Right value
        // exists to provide. Now surfaced via ProfileState.photoUrl.
        emit(
          state.copyWith(
            message: () => 'profile.picture_updated',
            photoUrl: () => downloadUrl,
          ),
        );
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
    // Equip-only, no coin deduction — kept on the generic updateUser path.
    // Unlike the purchase handlers below, there's no balance to protect
    // here, and this matches the same "trust the client to only equip an
    // already-owned item" pattern equipKidsAccessory/updateKidsMascot
    // already use elsewhere in this app; the worst case on a race is a
    // benign last-write-wins between two equip taps, not a currency bug.
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

  /// Purchases (or re-equips) a furniture item via the transaction-safe
  /// [ShopRepository.buyKidsFurniture].
  ///
  /// Previously deducted [event.cost] from [kidsCoins] client-side and
  /// persisted the full user document with no transaction — this method's
  /// own doc comment flagged exactly that as needing "a dedicated
  /// `ShopRepository.buyFurniture()` transaction method", which now exists.
  Future<void> _onBuyFurniture(
    ProfileBuyFurnitureRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await buyKidsFurniture(
      BuyKidsFurnitureParams(
        category: event.category,
        furnitureId: event.furnitureId,
        cost: event.cost,
      ),
    );
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => authBloc.add(const AuthReloadUser()),
    );
  }

  Future<void> _onUpdateVowlMascot(
    ProfileUpdateVowlMascotRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // Equip-only — see _onUpdateFurniture's comment for why this stays on
    // the generic updateUser path.
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

  /// Purchases (or re-equips) a Vowl mascot via the transaction-safe
  /// [ShopRepository.buyVowlMascot]. See [_onBuyFurniture]'s doc comment —
  /// same fix, same reason.
  Future<void> _onBuyVowlMascot(
    ProfileBuyVowlMascotRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await buyVowlMascot(
      BuyVowlMascotParams(mascotId: event.mascotId, cost: event.cost),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          message: () => failure.message,
          lastPurchaseType: () => 'vowl_mascot',
          lastPurchaseSuccess: () => false,
        ),
      ),
      (_) {
        authBloc.add(const AuthReloadUser());
        emit(
          state.copyWith(
            lastPurchaseType: () => 'vowl_mascot',
            lastPurchaseSuccess: () => true,
          ),
        );
      },
    );
  }

  /// Purchases (or re-equips) a Vowl accessory via the transaction-safe
  /// [ShopRepository.buyVowlAccessory]. See [_onBuyFurniture]'s doc comment
  /// — same fix, same reason (this method's own comment previously flagged
  /// it as sharing "the same concurrency caveat as [_onBuyFurniture]").
  Future<void> _onBuyVowlAccessory(
    ProfileBuyVowlAccessoryRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await buyVowlAccessory(
      BuyVowlAccessoryParams(accessoryId: event.accessoryId, cost: event.cost),
    );
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

  /// Credits [event.amount] Golden Keys via the atomic
  /// [GamificationRepository.addGoldenKey].
  ///
  /// Previously read `user.keys` from the (potentially stale) cached
  /// [AuthBloc] state, computed `(user.keys + event.amount).clamp(0, 9999)`
  /// client-side, and wrote it back via a generic `updateUser` call — a
  /// lost-update race if this fires twice before the cache refreshes, and
  /// (independently) `.clamp(0, 9999)` on an `int` returns `num`, which is
  /// not assignable to `UserEntity.copyWith`'s `int? keys` parameter — the
  /// same static-type error found and fixed in
  /// `GamificationRepositoryImpl.updateCategoryStats` during the earlier
  /// repository-layer review. Both issues disappear together: the atomic
  /// `FieldValue.increment` this now delegates to needs no client-side
  /// arithmetic at all.
  Future<void> _onUpdateKeys(
    ProfileUpdateKeysRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await addGoldenKey(AddGoldenKeyParams(amount: event.amount));
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => authBloc.add(const AuthReloadUser()),
    );
  }

  /// Purchases a Golden Key via the transaction-safe
  /// [GamificationRepository.purchaseGoldenKey].
  ///
  /// Previously read `user.coins`/`user.kidsCoins` from the cached
  /// [AuthBloc] state, validated and deducted client-side, and wrote the
  /// result back via a generic `updateUser` call with no transaction —
  /// exactly the kind of concurrent-purchase race this whole review's
  /// repository-layer batch introduced Firestore transactions to close for
  /// every *other* currency operation. This use case already existed and
  /// was already safe; this handler just wasn't using it.
  Future<void> _onBuyKey(
    ProfileBuyKeyRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final result = await purchaseGoldenKey(
      PurchaseGoldenKeyParams(cost: event.cost, isKidsMode: event.isKidsMode),
    );
    result.fold(
      (failure) => emit(state.copyWith(message: () => failure.message)),
      (_) => authBloc.add(const AuthReloadUser()),
    );
  }

  /// Persists buddy-room lifecycle fields via the generic [updateUser] path.
  ///
  /// This is non-transactional (equip-only pattern — no currency at risk).
  /// The buddy state is advisory/cosmetic, so last-write-wins is acceptable.
  Future<void> _onUpdateBuddyRoom(
    ProfileUpdateBuddyRoomRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_isAuthenticated) return;
    final user = authBloc.state.user;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (event.mood != null) updates['kidsBuddyMood'] = event.mood;
    if (event.energy != null) updates['kidsBuddyEnergy'] = event.energy;
    if (event.hunger != null) updates['kidsBuddyHunger'] = event.hunger;
    if (event.careStreak != null) updates['kidsCareStreak'] = event.careStreak;
    if (event.roomLevel != null) updates['kidsRoomLevel'] = event.roomLevel;
    if (event.theme != null) updates['kidsRoomTheme'] = event.theme;
    if (event.lastCareDate != null) updates['kidsLastCareDate'] = Timestamp.fromDate(event.lastCareDate!);
    if (event.lastFeedTime != null) updates['kidsLastFeedTime'] = Timestamp.fromDate(event.lastFeedTime!);
    if (event.gamesPlayedToday != null) updates['kidsGamesPlayedToday'] = event.gamesPlayedToday;
    if (event.lastGameDate != null) updates['kidsLastGameDate'] = Timestamp.fromDate(event.lastGameDate!);

    if (updates.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.id).update(updates);
        authBloc.add(const AuthReloadUser());
      } catch (e) {
        emit(state.copyWith(message: () => e.toString()));
      }
    }
  }
}
