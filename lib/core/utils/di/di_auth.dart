import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/utils/notification_service.dart';
import 'package:vowl/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:vowl/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';
import 'package:vowl/features/auth/domain/repositories/user_repository.dart';
import 'package:vowl/features/auth/data/repositories/user_repository_impl.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';
import 'package:vowl/features/auth/data/repositories/gamification_repository_impl.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';
import 'package:vowl/features/auth/data/repositories/shop_repository_impl.dart';
import 'package:vowl/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:vowl/features/leaderboard/data/repositories/leaderboard_repository_impl.dart';

import 'package:vowl/features/auth/domain/usecases/sign_up.dart';
import 'package:vowl/features/auth/domain/usecases/log_in_with_email.dart';
import 'package:vowl/features/auth/domain/usecases/log_in_with_google.dart';
import 'package:vowl/features/auth/domain/usecases/log_out.dart';
import 'package:vowl/features/auth/domain/usecases/get_user_stream.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_coins.dart';
import 'package:vowl/features/auth/domain/usecases/update_category_stats.dart';
import 'package:vowl/features/auth/domain/usecases/award_badge.dart';
import 'package:vowl/features/auth/domain/usecases/forgot_password.dart';
import 'package:vowl/features/auth/domain/usecases/send_email_verification.dart';
import 'package:vowl/features/auth/domain/usecases/reload_user.dart';
import 'package:vowl/features/auth/domain/usecases/get_current_user.dart';
import 'package:vowl/features/auth/domain/usecases/update_user_rewards.dart';
import 'package:vowl/features/auth/domain/usecases/update_user.dart';
import 'package:vowl/features/auth/domain/usecases/claim_vip_gift.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_hint.dart';
import 'package:vowl/features/auth/domain/usecases/use_hint.dart';
import 'package:vowl/features/auth/domain/usecases/update_profile_picture.dart';
import 'package:vowl/features/auth/domain/usecases/update_display_name.dart';
import 'package:vowl/features/auth/domain/usecases/repair_streak.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_streak_freeze.dart';
import 'package:vowl/features/auth/domain/usecases/activate_double_xp.dart';
import 'package:vowl/features/auth/domain/usecases/delete_account.dart';
import 'package:vowl/features/auth/domain/usecases/claim_daily_gift.dart';
import 'package:vowl/features/auth/domain/usecases/claim_daily_chest.dart';
import 'package:vowl/features/auth/domain/usecases/claim_kids_daily_reward.dart';
import 'package:vowl/features/auth/domain/usecases/award_kids_coins.dart';
import 'package:vowl/features/auth/domain/usecases/award_kids_sticker.dart';
import 'package:vowl/features/auth/domain/usecases/update_kids_mascot.dart';
import 'package:vowl/features/auth/domain/usecases/buy_kids_accessory.dart';
import 'package:vowl/features/auth/domain/usecases/equip_kids_accessory.dart';
import 'package:vowl/features/auth/domain/usecases/update_unlocked_level.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_level_unlock.dart';
import 'package:vowl/features/auth/domain/usecases/purchase_golden_key.dart';
import 'package:vowl/features/auth/domain/usecases/add_golden_key.dart';
import 'package:vowl/features/writing/domain/usecases/use_writing_hint.dart';

import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/progression_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/login_cubit.dart';
import 'package:vowl/features/auth/presentation/bloc/signup_cubit.dart';
import 'package:vowl/features/auth/presentation/bloc/forgot_password_cubit.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';

/// Initialises authentication, profile, economy, and progression modules.
void initAuthFeature(GetIt sl) {
  // ============================================================
  // DATA SOURCES
  // ============================================================
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      googleSignIn: sl<GoogleSignIn>(),
    ),
  );

  // ============================================================
  // REPOSITORIES
  // ============================================================
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
      firebaseMessaging: sl<FirebaseMessaging>(),
    ),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
      storage: sl<FirebaseStorage>(),
    ),
  );
  sl.registerLazySingleton<GamificationRepository>(
    () => GamificationRepositoryImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );
  sl.registerLazySingleton<ShopRepository>(
    () => ShopRepositoryImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );
  sl.registerLazySingleton<LeaderboardRepository>(
    () => LeaderboardRepositoryImpl(sl<FirebaseFirestore>()),
  );

  // ============================================================
  // DOMAIN USE CASES
  // ============================================================
  sl.registerLazySingleton<SignUp>(() => SignUp(sl<AuthRepository>()));
  sl.registerLazySingleton<LogInWithEmail>(
    () => LogInWithEmail(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogInWithGoogle>(
    () => LogInWithGoogle(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ForgotPassword>(
    () => ForgotPassword(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<LogOut>(() => LogOut(sl<AuthRepository>()));
  sl.registerLazySingleton<GetUserStream>(
    () => GetUserStream(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<UpdateUserCoins>(
    () => UpdateUserCoins(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<UpdateCategoryStats>(
    () => UpdateCategoryStats(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<AwardBadge>(
    () => AwardBadge(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<AwardKidsSticker>(
    () => AwardKidsSticker(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<UpdateKidsMascot>(
    () => UpdateKidsMascot(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<BuyKidsAccessory>(
    () => BuyKidsAccessory(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<EquipKidsAccessory>(
    () => EquipKidsAccessory(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<UpdateUnlockedLevel>(
    () => UpdateUnlockedLevel(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<PurchaseLevelUnlock>(
    () => PurchaseLevelUnlock(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<PurchaseGoldenKey>(
    () => PurchaseGoldenKey(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<AddGoldenKey>(
    () => AddGoldenKey(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<SendEmailVerification>(
    () => SendEmailVerification(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ReloadUser>(() => ReloadUser(sl<AuthRepository>()));
  sl.registerLazySingleton<GetCurrentUser>(
    () => GetCurrentUser(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<UpdateUser>(() => UpdateUser(sl<UserRepository>()));
  sl.registerLazySingleton<ClaimVipGift>(
    () => ClaimVipGift(sl<UserRepository>()),
  );
  sl.registerLazySingleton<PurchaseHint>(
    () => PurchaseHint(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<UseHint>(() => UseHint(sl<ShopRepository>()));
  sl.registerLazySingleton<UseWritingHint>(
    () => UseWritingHint(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<UpdateUserRewards>(
    () => UpdateUserRewards(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<UpdateProfilePicture>(
    () => UpdateProfilePicture(sl<UserRepository>()),
  );
  sl.registerLazySingleton<UpdateDisplayName>(
    () => UpdateDisplayName(sl<UserRepository>()),
  );
  sl.registerLazySingleton<RepairStreak>(
    () => RepairStreak(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<PurchaseStreakFreeze>(
    () => PurchaseStreakFreeze(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<ActivateDoubleXP>(
    () => ActivateDoubleXP(sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<DeleteAccount>(
    () => DeleteAccount(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<ClaimDailyGift>(
    () => ClaimDailyGift(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<ClaimDailyChest>(
    () => ClaimDailyChest(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<ClaimKidsDailyReward>(
    () => ClaimKidsDailyReward(sl<ShopRepository>()),
  );
  sl.registerLazySingleton<AwardKidsCoins>(
    () => AwardKidsCoins(sl<ShopRepository>()),
  );

  // ============================================================
  // PRESENTATION — SINGLETON BLOCS
  // These hold long-lived state shared across the widget tree.
  // ============================================================
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      getUserStream: sl<GetUserStream>(),
      logOut: sl<LogOut>(),
      reloadUser: sl<ReloadUser>(),
      deleteAccount: sl<DeleteAccount>(),
      forgotPassword: sl<ForgotPassword>(),
      getCurrentUser: sl<GetCurrentUser>(),
      sendEmailVerification: sl<SendEmailVerification>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton<EconomyBloc>(
    () => EconomyBloc(
      updateUserCoins: sl<UpdateUserCoins>(),
      purchaseHint: sl<PurchaseHint>(),
      claimVipGift: sl<ClaimVipGift>(),
      claimDailyGift: sl<ClaimDailyGift>(),
      updateUser: sl<UpdateUser>(),
      claimDailyChest: sl<ClaimDailyChest>(),
      claimKidsDailyReward: sl<ClaimKidsDailyReward>(),
      awardKidsCoins: sl<AwardKidsCoins>(),
      useHint: sl<UseHint>(),
      authBloc: sl<AuthBloc>(),
    ),
  );
  sl.registerLazySingleton<ProgressionBloc>(
    () => ProgressionBloc(
      repairStreak: sl<RepairStreak>(),
      purchaseStreakFreeze: sl<PurchaseStreakFreeze>(),
      activateDoubleXP: sl<ActivateDoubleXP>(),
      updateUser: sl<UpdateUser>(),
      authBloc: sl<AuthBloc>(),
      notificationService: sl<NotificationService>(),
    ),
  );
  sl.registerLazySingleton<ProfileBloc>(
    () => ProfileBloc(
      updateDisplayName: sl<UpdateDisplayName>(),
      updateProfilePicture: sl<UpdateProfilePicture>(),
      updateKidsMascot: sl<UpdateKidsMascot>(),
      buyKidsAccessory: sl<BuyKidsAccessory>(),
      equipKidsAccessory: sl<EquipKidsAccessory>(),
      updateUser: sl<UpdateUser>(),
      authBloc: sl<AuthBloc>(),
    ),
  );

  // ============================================================
  // PRESENTATION — FACTORY BLOCS / CUBITS
  // Per-screen instances; created fresh for each navigation.
  // ============================================================
  sl.registerFactory<LoginCubit>(
    () => LoginCubit(
      logInWithEmail: sl<LogInWithEmail>(),
      logInWithGoogle: sl<LogInWithGoogle>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerFactory<SignUpCubit>(
    () => SignUpCubit(
      signUp: sl<SignUp>(),
      sendEmailVerification: sl<SendEmailVerification>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );
  sl.registerFactory<ForgotPasswordCubit>(
    () => ForgotPasswordCubit(
      forgotPassword: sl<ForgotPassword>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // FIX (CRITICAL-1): ThemeCubit MUST be a lazy singleton.
  //
  // Previously registered as `registerFactory`, which created a NEW ThemeCubit
  // instance on every `sl<ThemeCubit>()` call. Each instance independently
  // loads SharedPreferences. The MaterialApp's ThemeCubit and any screen-level
  // resolution would be completely different objects — the user's chosen theme
  // appeared to reset on every navigation event.
  //
  // As a LazyRegistration, a single instance is created on first access and
  // reused for the entire app lifetime, correctly sharing theme state.
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit());

  // LeaderboardBloc is correctly a Factory — it is created per-screen and
  // disposed when the Leaderboard screen is popped.
  sl.registerFactory<LeaderboardBloc>(
    () => LeaderboardBloc(repository: sl<LeaderboardRepository>()),
  );
}
