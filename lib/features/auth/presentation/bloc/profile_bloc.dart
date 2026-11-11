import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/auth_error_handler.dart';
import 'package:vowl/features/auth/domain/usecases/add_golden_key.dart';
import 'package:vowl/features/auth/domain/usecases/buy_vowl_accessory.dart';
import 'package:vowl/features/auth/domain/usecases/buy_vowl_mascot.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_golden_key.dart';
import 'package:vowl/features/auth/domain/usecases/update_display_name.dart';
import 'package:vowl/features/auth/domain/usecases/update_profile_picture.dart';
import 'package:vowl/features/auth/domain/usecases/update_user.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

// ============================================================================
// EVENTS
// ============================================================================

/// Base class for all profile BLoC events.
abstract class ProfileEvent extends Equatable {
  /// Const constructor for sub-classes.
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileClearPurchaseFeedback extends ProfileEvent {
  const ProfileClearPurchaseFeedback();
}

/// Clears transient feedback or notification messages after display.
class ProfileClearMessage extends ProfileEvent {
  const ProfileClearMessage();
}

/// Clears immediate optimistic profile photo and its user association.
class ProfileClearImmediatePhoto extends ProfileEvent {
  const ProfileClearImmediatePhoto();
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

class ProfileUpdateKeysRequested extends ProfileEvent {
  final int amount;
  const ProfileUpdateKeysRequested(this.amount);
  @override
  List<Object?> get props => [amount];
}

class ProfileBuyKeyRequested extends ProfileEvent {
  final int cost;
  const ProfileBuyKeyRequested({required this.cost});
  @override
  List<Object?> get props => [cost];
}

// ============================================================================
// STATE
// ============================================================================

class ProfileState extends Equatable {
  final String? message;
  final bool isLoading;
  final bool isPhotoUploading;
  final String? lastPurchaseType;
  final bool? lastPurchaseSuccess;

  /// The freshly-uploaded profile picture's download URL, available
  /// immediately on a successful [ProfileUpdatePictureRequested] — before
  /// [AuthBloc]'s reload round-trip completes.
  final String? photoUrl;

  /// The user ID that owns [photoUrl]. Prevents another account on the same
  /// device from displaying a previously-uploaded avatar.
  final String? photoUserId;

  const ProfileState({
    this.message,
    this.isLoading = false,
    this.isPhotoUploading = false,
    this.lastPurchaseType,
    this.lastPurchaseSuccess,
    this.photoUrl,
    this.photoUserId,
  });

  /// Returns true only if [photoUrl] belongs to the currently active user with [userId].
  bool isPhotoForUser(String? userId) =>
      photoUrl != null &&
      photoUserId != null &&
      userId != null &&
      photoUserId == userId;

  ProfileState copyWith({
    String? Function()? message,
    bool? isLoading,
    bool? isPhotoUploading,
    String? Function()? lastPurchaseType,
    bool? Function()? lastPurchaseSuccess,
    String? Function()? photoUrl,
    String? Function()? photoUserId,
  }) {
    return ProfileState(
      message: message != null ? message() : this.message,
      isLoading: isLoading ?? this.isLoading,
      isPhotoUploading: isPhotoUploading ?? this.isPhotoUploading,
      lastPurchaseType: lastPurchaseType != null
          ? lastPurchaseType()
          : this.lastPurchaseType,
      lastPurchaseSuccess: lastPurchaseSuccess != null
          ? lastPurchaseSuccess()
          : this.lastPurchaseSuccess,
      photoUrl: photoUrl != null ? photoUrl() : this.photoUrl,
      photoUserId: photoUserId != null ? photoUserId() : this.photoUserId,
    );
  }

  @override
  List<Object?> get props => [
    message,
    isLoading,
    isPhotoUploading,
    lastPurchaseType,
    lastPurchaseSuccess,
    photoUrl,
    photoUserId,
  ];
}

// ============================================================================
// BLOC
// ============================================================================

/// BLoC managing user profile settings, avatars, cosmetics, and accessories.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UpdateDisplayName updateDisplayName;
  final UpdateProfilePicture updateProfilePicture;
  final UpdateUser updateUser;
  final AuthBloc authBloc;
  final NetworkInfo _networkInfo;

  // Added to replace unsafe client-side purchase/credit logic previously
  // implemented via a generic `updateUser` full-document write — see each
  // handler's doc comment below for what specifically changed and why.
  final BuyVowlMascot buyVowlMascot;
  final BuyVowlAccessory buyVowlAccessory;
  final PurchaseGoldenKey purchaseGoldenKey;
  final AddGoldenKey addGoldenKey;

  StreamSubscription<AuthState>? _authSubscription;

  /// Creates a [ProfileBloc] instance with all required profile and customization use cases.
  ProfileBloc({
    required this.updateDisplayName,
    required this.updateProfilePicture,
    required this.updateUser,
    required this.authBloc,
    required this.buyVowlMascot,
    required this.buyVowlAccessory,
    required this.purchaseGoldenKey,
    required this.addGoldenKey,
    required NetworkInfo networkInfo,
  }) : _networkInfo = networkInfo,
       super(const ProfileState()) {
    on<ProfileUpdateDisplayNameRequested>(_onUpdateDisplayName);
    on<ProfileUpdatePictureRequested>(_onUpdatePicture);
    on<ProfileClearImmediatePhoto>(
      (_, emit) =>
          emit(state.copyWith(photoUrl: () => null, photoUserId: () => null)),
    );
    on<ProfileClearMessage>(
      (_, emit) => emit(state.copyWith(message: () => null)),
    );
    on<ProfileUpdateVowlMascotRequested>(_onUpdateVowlMascot);
    on<ProfileBuyVowlMascotRequested>(_onBuyVowlMascot);
    on<ProfileBuyVowlAccessoryRequested>(_onBuyVowlAccessory);
    on<ProfileEquipVowlAccessoryRequested>(_onEquipVowlAccessory);
    on<ProfileUpdateKeysRequested>(_onUpdateKeys);
    on<ProfileBuyKeyRequested>(_onBuyKey);
    on<ProfileClearPurchaseFeedback>(
      (_, emit) => emit(
        state.copyWith(
          lastPurchaseType: () => null,
          lastPurchaseSuccess: () => null,
        ),
      ),
    );

    // Watch auth state to prevent avatar bleed across multi-account sessions:
    // 1. Clears cached immediate photo if user logs out or switches accounts.
    // 2. Clears immediate override once backend round-trip sync completes.
    _authSubscription = authBloc.stream.listen((authState) {
      final currentUserId = authState.user?.id;
      if (currentUserId == null ||
          (state.photoUserId != null && state.photoUserId != currentUserId)) {
        add(const ProfileClearImmediatePhoto());
      } else if (state.photoUrl != null &&
          authState.user?.photoUrl == state.photoUrl) {
        add(const ProfileClearImmediatePhoto());
      }
    });
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
    if (state.isLoading) return;
    if (!(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          isLoading: false,
          isPhotoUploading: false,
          message: () => AuthErrorHandler.getKey('network-unreachable'),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        isLoading: true,
        isPhotoUploading: false,
        message: () => null,
      ),
    );
    if (!_isAuthenticated) {
      emit(state.copyWith(isLoading: false, isPhotoUploading: false));
      return;
    }
    final result = await updateDisplayName(event.displayName);
    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          isPhotoUploading: false,
          message: () => AuthErrorHandler.getKey(failure.message),
        ),
      ),
      (_) {
        // 'profile.display_name_updated' is a stable key, not English
        // display text — see GamificationRepositoryImpl's class doc for the
        // full localization rationale applied consistently across this
        // review; the previous literal ('Name updated!') could never be
        // localized for any of this app's other 17 target languages.
        emit(
          state.copyWith(
            isLoading: false,
            isPhotoUploading: false,
            message: () => 'profile.display_name_updated',
          ),
        );
        authBloc.add(const AuthReloadUser());
      },
    );
  }

  Future<void> _onUpdatePicture(
    ProfileUpdatePictureRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.isLoading) return;
    if (!(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          isLoading: false,
          isPhotoUploading: false,
          message: () => AuthErrorHandler.getKey('network-unreachable'),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        isLoading: true,
        isPhotoUploading: true,
        message: () => null,
      ),
    );
    if (!_isAuthenticated) {
      emit(state.copyWith(isLoading: false, isPhotoUploading: false));
      return;
    }
    final result = await updateProfilePicture(event.filePath);
    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          isPhotoUploading: false,
          message: () => AuthErrorHandler.getKey(failure.message),
        ),
      ),
      (downloadUrl) {
        // Previously this branch was `(_) { ... }` — discarding the
        // download URL entirely and relying solely on AuthReloadUser's
        // round trip. That throws away exactly the immediacy
        // UpdateProfilePicture's own doc comment says this Right value
        // exists to provide. Now surfaced via ProfileState.photoUrl,
        // and tagged with the current active user ID to ensure other
        // accounts on the same device never see it.
        final currentUserId = authBloc.state.user?.id;
        emit(
          state.copyWith(
            isLoading: false,
            isPhotoUploading: false,
            message: () => 'profile.picture_updated',
            photoUrl: () => downloadUrl,
            photoUserId: () => currentUserId,
          ),
        );
        authBloc.add(const AuthReloadUser());
      },
    );
  }



  Future<void> _onUpdateVowlMascot(
    ProfileUpdateVowlMascotRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // Equip-only — see _onUpdateFurniture's comment for why this stays on
    // the generic updateUser path.
    if (state.isLoading) return;
    if (!(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          isLoading: false,
          message: () => AuthErrorHandler.getKey('network-unreachable'),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        isLoading: true,
        isPhotoUploading: false,
        message: () => null,
      ),
    );
    if (!_isAuthenticated) {
      emit(state.copyWith(isLoading: false));
      return;
    }
    final user = authBloc.state.user;
    if (user == null) {
      emit(state.copyWith(isLoading: false));
      return;
    }

    final updatedUser = user.copyWith(vowlMascot: event.mascotId);
    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          message: () => AuthErrorHandler.getKey(failure.message),
        ),
      ),
      (_) {
        emit(state.copyWith(isLoading: false));
        authBloc.add(const AuthReloadUser());
      },
    );
  }

  /// Purchases (or re-equips) a Vowl mascot via the transaction-safe
  /// [ShopRepository.buyVowlMascot]. See [_onBuyFurniture]'s doc comment —
  /// same fix, same reason.
  Future<void> _onBuyVowlMascot(
    ProfileBuyVowlMascotRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.isLoading) return;
    if (!(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          isLoading: false,
          message: () => AuthErrorHandler.getKey('network-unreachable'),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        isLoading: true,
        isPhotoUploading: false,
        message: () => null,
      ),
    );
    if (!_isAuthenticated) {
      emit(state.copyWith(isLoading: false));
      return;
    }
    final result = await buyVowlMascot(
      BuyVowlMascotParams(mascotId: event.mascotId, cost: event.cost),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          isPhotoUploading: false,
          message: () => AuthErrorHandler.getKey(failure.message),
          lastPurchaseType: () => 'vowl_mascot',
          lastPurchaseSuccess: () => false,
        ),
      ),
      (_) {
        authBloc.add(const AuthReloadUser());
        emit(
          state.copyWith(
            isLoading: false,
            isPhotoUploading: false,
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
    if (state.isLoading) return;
    if (!(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          isLoading: false,
          isPhotoUploading: false,
          message: () => AuthErrorHandler.getKey('network-unreachable'),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        isLoading: true,
        isPhotoUploading: false,
        message: () => null,
      ),
    );
    if (!_isAuthenticated) {
      emit(state.copyWith(isLoading: false));
      return;
    }
    final result = await buyVowlAccessory(
      BuyVowlAccessoryParams(accessoryId: event.accessoryId, cost: event.cost),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          isPhotoUploading: false,
          message: () => AuthErrorHandler.getKey(failure.message),
          lastPurchaseType: () => 'vowl_accessory',
          lastPurchaseSuccess: () => false,
        ),
      ),
      (_) {
        authBloc.add(const AuthReloadUser());
        emit(
          state.copyWith(
            isLoading: false,
            isPhotoUploading: false,
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
    if (state.isLoading) return;
    if (!(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          isLoading: false,
          message: () => AuthErrorHandler.getKey('network-unreachable'),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        isLoading: true,
        isPhotoUploading: false,
        message: () => null,
      ),
    );
    if (!_isAuthenticated) {
      emit(state.copyWith(isLoading: false));
      return;
    }
    final user = authBloc.state.user;
    if (user == null) {
      emit(state.copyWith(isLoading: false));
      return;
    }

    final updatedUser = user.copyWith(vowlEquippedAccessory: event.accessoryId);
    final result = await updateUser(UpdateUserParams(user: updatedUser));
    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          message: () => AuthErrorHandler.getKey(failure.message),
        ),
      ),
      (_) {
        emit(state.copyWith(isLoading: false));
        authBloc.add(const AuthReloadUser());
      },
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
    if (state.isLoading) return;
    if (!(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          isLoading: false,
          message: () => AuthErrorHandler.getKey('network-unreachable'),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        isLoading: true,
        isPhotoUploading: false,
        message: () => null,
      ),
    );
    if (!_isAuthenticated) {
      emit(state.copyWith(isLoading: false));
      return;
    }
    final result = await addGoldenKey(AddGoldenKeyParams(amount: event.amount));
    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          message: () => AuthErrorHandler.getKey(failure.message),
        ),
      ),
      (_) {
        emit(state.copyWith(isLoading: false));
        authBloc.add(const AuthReloadUser());
      },
    );
  }

  /// Purchases a Golden Key via the transaction-safe
  /// [GamificationRepository.purchaseGoldenKey].
  Future<void> _onBuyKey(
    ProfileBuyKeyRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.isLoading) return;
    if (!(await _networkInfo.isConnected)) {
      emit(
        state.copyWith(
          isLoading: false,
          message: () => AuthErrorHandler.getKey('network-unreachable'),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        isLoading: true,
        isPhotoUploading: false,
        message: () => null,
      ),
    );
    if (!_isAuthenticated) {
      emit(state.copyWith(isLoading: false));
      return;
    }
    final result = await purchaseGoldenKey(
      PurchaseGoldenKeyParams(cost: event.cost),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          message: () => AuthErrorHandler.getKey(failure.message),
        ),
      ),
      (_) {
        emit(state.copyWith(isLoading: false));
        authBloc.add(const AuthReloadUser());
      },
    );
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
